// services/event.apply.service.js
const mongoose = require("mongoose");
const InventoryItem = require("../models/inventory.model");
const Event = require("../models/event.model"); // bạn đã có
const axios = require("axios");

// ==== CONFIG gọi catalog-service để lấy danh sách tour khi apply_to_all_tours ====
const CATALOG_BASE_URL =
  process.env.CATALOG_BASE_URL ||
  process.env.GATEWAY_URL ||
  "http://localhost:3000";

function computeDiscountedPrice(base, type, value) {
  const b = Math.max(0, Number(base || 0));
  const v = Number(value || 0);

  if (type === "percentage") {
    // giảm %: b * (100 - v) / 100
    const pct = Math.min(99, Math.max(0, v));
    return Math.max(0, Math.round((b * (100 - pct)) / 100));
  }

  // fixed_amount
  return Math.max(0, b - v);
}

// yearly-range (có xử lý case qua năm, vd 20/12 -> 10/01)
function isNowInYearlyRange(now, sm, sd, em, ed) {
  const year = now.getFullYear();
  const start = new Date(year, sm - 1, sd, 0, 0, 0);
  const end = new Date(year, em - 1, ed, 23, 59, 59);

  // không qua năm
  if (start <= end) return now >= start && now <= end;

  // qua năm: (start -> 31/12) OR (01/01 -> end)
  const endOfYear = new Date(year, 11, 31, 23, 59, 59);
  const startOfYear = new Date(year, 0, 1, 0, 0, 0);
  return (
    (now >= start && now <= endOfYear) || (now >= startOfYear && now <= end)
  );
}

async function fetchAllTourIdsFromCatalog() {
  // frontend đang gọi: GET /products?product_type=tour&page=1&limit=500 :contentReference[oaicite:4]{index=4}
  const res = await axios.get(`${CATALOG_BASE_URL}/products`, {
    params: { product_type: "tour", page: 1, limit: 5000 },
  });

  const data = res.data;
  const list =
    (Array.isArray(data) && data) ||
    data?.products ||
    data?.items ||
    data?.data ||
    [];

  return list.map((t) => String(t._id || t.id)).filter(Boolean);
}

function eventAppliesToTour(ev, tourIdStr) {
  if (ev.apply_to_all_tours) return true;
  const ids = Array.isArray(ev.tour_ids) ? ev.tour_ids.map(String) : [];
  return ids.includes(String(tourIdStr));
}

function pickWinningEventForTour(events, tourIdStr) {
  const applicable = events.filter((ev) => eventAppliesToTour(ev, tourIdStr));
  if (applicable.length === 0) return null;

  applicable.sort((a, b) => {
    const pa = Number(a.priority || 0);
    const pb = Number(b.priority || 0);
    if (pb !== pa) return pb - pa;
    return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
  });

  return applicable[0];
}

async function getActiveEventsNow(now = new Date()) {
  const events = await Event.find({ is_active: true }).lean();

  // lọc theo range nếu is_yearly
  return events.filter((ev) => {
    if (ev.is_yearly === false) return true; // nếu bạn có loại không-yearly
    return isNowInYearlyRange(
      now,
      Number(ev.start_month || 1),
      Number(ev.start_day || 1),
      Number(ev.end_month || 12),
      Number(ev.end_day || 31)
    );
  });
}

async function syncPricesForTour(productIdStr, activeEvents) {
  const productId = new mongoose.Types.ObjectId(productIdStr);

  const winning = pickWinningEventForTour(activeEvents, productIdStr);

  const items = await InventoryItem.find({ product_id: productId });

  if (!items.length) return { productId: productIdStr, updated: 0 };

  const ops = [];

  for (const it of items) {
    const base = Number(it.original_price ?? it.price ?? 0);

    if (!winning) {
      // revert nếu đang có original_price
      if (it.original_price != null || it.applied_event?.event_id) {
        ops.push({
          updateOne: {
            filter: { _id: it._id },
            update: {
              $set: { price: base },
              $unset: { original_price: "", applied_event: "" },
            },
          },
        });
      }
      continue;
    }

    const newPrice = computeDiscountedPrice(
      base,
      winning.discount_type,
      winning.discount_value
    );

    ops.push({
      updateOne: {
        filter: { _id: it._id },
        update: {
          $set: {
            price: newPrice,
            // chỉ set original_price lần đầu
            original_price:
              it.original_price == null ? base : it.original_price,
            applied_event: {
              event_id: winning._id,
              name: winning.name,
              discount_type: winning.discount_type,
              discount_value: winning.discount_value,
              priority: Number(winning.priority || 0),
              applied_at: new Date(),
            },
          },
        },
      },
    });
  }

  if (!ops.length) return { productId: productIdStr, updated: 0 };

  const r = await InventoryItem.bulkWrite(ops, { ordered: false });
  return { productId: productIdStr, updated: r.modifiedCount || 0 };
}

async function syncAllPricesNow() {
  const activeEvents = await getActiveEventsNow(new Date());

  // lấy danh sách tourId cần sync:
  // nếu có event apply_all -> sync ALL tours
  const hasAll = activeEvents.some((e) => e.apply_to_all_tours);

  let tourIds = [];
  if (hasAll) {
    tourIds = await fetchAllTourIdsFromCatalog();
  } else {
    const set = new Set();
    for (const ev of activeEvents) {
      (ev.tour_ids || []).forEach((id) => set.add(String(id)));
    }
    tourIds = Array.from(set);
  }

  const results = [];
  for (const tid of tourIds) {
    results.push(await syncPricesForTour(tid, activeEvents));
  }
  return { tourCount: tourIds.length, results };
}

async function syncPricesForEventChange(eventDoc) {
  // Khi tạo/sửa/toggle 1 event, chỉ sync tour liên quan (nhanh hơn)
  const now = new Date();
  const activeEvents = await getActiveEventsNow(now);

  // tourIds cần sync = (event apply_all ? ALL tours : event.tour_ids)
  let tourIds = [];
  if (eventDoc.apply_to_all_tours) {
    tourIds = await fetchAllTourIdsFromCatalog();
  } else {
    tourIds = (eventDoc.tour_ids || []).map(String);
  }

  const results = [];
  for (const tid of tourIds) {
    results.push(await syncPricesForTour(tid, activeEvents));
  }

  return { tourCount: tourIds.length, results };
}

module.exports = {
  syncAllPricesNow,
  syncPricesForEventChange,
};
