const catalog = require("./catalog.client");
const { embedText } = require("./llm/ollama.client");
const { ensureCollection, upsertPoints } = require("./vector/qdrant.client");
const crypto = require("crypto");

function mongoIdToUuid(mongoId) {
  // deterministic UUID from Mongo ObjectId (sha1 -> 16 bytes -> RFC4122)
  const hash = crypto.createHash("sha1").update(String(mongoId)).digest(); // 20 bytes
  const b = Buffer.from(hash.slice(0, 16));

  // version 5
  b[6] = (b[6] & 0x0f) | 0x50;
  // variant RFC4122
  b[8] = (b[8] & 0x3f) | 0x80;

  const hex = b.toString("hex");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(
    12,
    16
  )}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

// Text chuẩn hóa để embedding
function buildTourText(t) {
  const title = t.title || t.name || "";
  const loc = t.location?.name || t.locationName || ""; // nếu bạn chưa populate thì có thể rỗng
  const cat = t.category?.name || "";
  const desc =
    t.description_short ||
    t.description_long ||
    t.short_description ||
    t.description ||
    "";
  const highlightsObj =
    t.tour_details?.trip_highlights || t.trip_highlights || null;
  const highlights = highlightsObj ? JSON.stringify(highlightsObj) : "";

  return [
    `Tên tour: ${title}`,
    `Điểm đến: ${loc}`,
    `Danh mục: ${cat}`,
    `Mô tả: ${desc}`,
    `Nổi bật: ${highlights}`,
  ]
    .filter(Boolean)
    .join("\n");
}

async function reindexTours() {
  // Bạn có thể tăng limit / phân trang nếu backend hỗ trợ
  const tours = await catalog.listTours({ limit: 200, page: 1 });
  if (!Array.isArray(tours) || tours.length === 0) return { indexed: 0 };

  // Lấy vector size bằng 1 embedding mẫu (để khỏi đoán dimension)
  const sampleVec = await embedText(buildTourText(tours[0]));
  await ensureCollection(sampleVec.length);

  const points = [];
  for (const t of tours) {
    const text = buildTourText(t);
    const vec = await embedText(text);

    const mongoId = String(t._id || t.id);
    const pointId = mongoIdToUuid(mongoId);

    points.push({
      id: pointId, // Qdrant id hợp lệ (UUID)
      vector: vec,
      payload: {
        id: mongoId, // id thật của tour (MongoId) để UI dùng
        title: t.title || t.name,
        location: t.location?.name || t.locationName || "",
        priceFrom: t.base_price || t.basePrice || t.priceFrom || null,
        image: t.images?.[0]?.url || t.image || t.thumbnail || null,
        text,
      },
    });
  }

  // Upsert theo batch để đỡ nặng
  const batchSize = 50;
  for (let i = 0; i < points.length; i += batchSize) {
    await upsertPoints(points.slice(i, i + batchSize));
  }

  return { indexed: points.length };
}

module.exports = { reindexTours };
