import React, { useEffect, useState } from "react";
import CrudTable from "../../components/admin/CrudTable";
import {
  STORE_KEY,
  getList,
  addItem,
  updateItem,
  deleteItem,
} from "../../data/adminStore";

function Block({ title, children }) {
  return (
    <div style={{ display: "grid", gap: 10 }}>
      <div style={{ fontWeight: 900, fontSize: 18 }}>{title}</div>
      {children}
    </div>
  );
}

export default function ManageHome() {
  const [events, setEvents] = useState([]);
  const [cities, setCities] = useState([]);
  const [htr, setHtr] = useState([]);
  const [hotels, setHotels] = useState([]);
  const [discountHotels, setDiscountHotels] = useState([]);
  const [cityDeals, setCityDeals] = useState([]);

  const reload = () => {
    setEvents(getList(STORE_KEY.home_events));
    setCities(getList(STORE_KEY.home_cities));
    setHtr(getList(STORE_KEY.home_hotelsTopRated));
    setHotels(getList(STORE_KEY.home_hotels));
    setDiscountHotels(getList(STORE_KEY.home_discount_hotels));
    setCityDeals(getList(STORE_KEY.home_city_deals));
  };

  useEffect(() => reload(), []);

  const crud = (key, setter) => ({
    onAdd: (item) => {
      addItem(key, item);
      setter(getList(key));
    },
    onUpdate: (id, patch) => {
      updateItem(key, id, patch);
      setter(getList(key));
    },
    onDelete: (id) => {
      deleteItem(key, id);
      setter(getList(key));
    },
    onToggleStatus: (id, current) => {
      updateItem(key, id, {
        status: current === "ACTIVE" ? "INACTIVE" : "ACTIVE",
      });
      setter(getList(key));
    },
  });

  // nhỏ gọn: import trực tiếp để dùng
  function updateItem(key, id, patch) {
    const list = getList(key);
    const next = list.map((x) => (x.id === id ? { ...x, ...patch } : x));
    localStorage.setItem(key, JSON.stringify(next));
  }

  return (
    <div style={{ display: "grid", gap: 14 }}>
      <div>
        <div style={{ fontWeight: 900, fontSize: 22 }}>Quản lý Home</div>
        <div style={{ color: "#6b7280" }}>
          CRUD theo HomeData: events, cities, hotelsTopRated, hotels,
          discount_hotels, CITY_DEALS.
        </div>
      </div>

      <Block title="Events (banner/ưu đãi)">
        <CrudTable
          title="Danh sách events"
          data={events}
          schema={[
            { key: "id", label: "ID", type: "text" },
            { key: "subtitle", label: "Subtitle", type: "text" },
            { key: "ctaLabel", label: "CTA", type: "text" },
            { key: "backgroundUrl", label: "Background URL", type: "text" },
          ]}
          {...crud(STORE_KEY.home_events, setEvents)}
        />
      </Block>

      <Block title="Cities">
        <CrudTable
          title="Danh sách cities"
          data={cities}
          schema={[
            { key: "id", label: "ID", type: "text" },
            { key: "title", label: "Tên thành phố", type: "text" },
            { key: "staysCount", label: "Số chỗ ở", type: "number" },
            { key: "imageUrl", label: "Image URL", type: "text" },
          ]}
          {...crud(STORE_KEY.home_cities, setCities)}
        />
      </Block>

      <Block title="Hotels Top Rated">
        <CrudTable
          title="Top rated"
          data={htr}
          schema={[
            { key: "id", label: "ID", type: "text" },
            { key: "title", label: "Tên", type: "text" },
            { key: "address", label: "Địa chỉ", type: "text" },
            { key: "rating", label: "Điểm", type: "number" },
            { key: "reviews", label: "Reviews", type: "number" },
            { key: "imageUrl", label: "Image URL", type: "text" },
          ]}
          {...crud(STORE_KEY.home_hotelsTopRated, setHtr)}
        />
      </Block>

      <Block title="Hotels (list)">
        <CrudTable
          title="Hotels"
          data={hotels}
          schema={[
            { key: "id", label: "ID", type: "text" },
            { key: "title", label: "Tên", type: "text" },
            { key: "address", label: "Địa chỉ", type: "text" },
            { key: "rating", label: "Điểm", type: "number" },
            { key: "reviews", label: "Reviews", type: "number" },
            { key: "imageUrl", label: "Image URL", type: "text" },
          ]}
          {...crud(STORE_KEY.home_hotels, setHotels)}
        />
      </Block>

      <Block title="Discount Hotels">
        <CrudTable
          title="Discount hotels"
          data={discountHotels}
          schema={[
            { key: "id", label: "ID", type: "text" },
            { key: "title", label: "Tên", type: "text" },
            { key: "address", label: "Địa chỉ", type: "text" },
            { key: "rating", label: "Điểm", type: "number" },
            { key: "reviews", label: "Reviews", type: "number" },
            { key: "imageUrl", label: "Image URL", type: "text" },
          ]}
          {...crud(STORE_KEY.home_discount_hotels, setDiscountHotels)}
        />
      </Block>

      <Block title="City Deals (Flights)">
        <CrudTable
          title="CITY_DEALS"
          data={cityDeals}
          schema={[
            { key: "id", label: "ID", type: "text" },
            { key: "title", label: "Tên", type: "text" },
            { key: "country", label: "Quốc gia", type: "text" },
            { key: "price", label: "Giá", type: "number" },
            { key: "popularScore", label: "Popular", type: "number" },
            { key: "fastestHours", label: "Nhanh nhất (giờ)", type: "number" },
          ]}
          {...crud(STORE_KEY.home_city_deals, setCityDeals)}
        />
      </Block>

      <div style={{ display: "flex", justifyContent: "flex-end" }}>
        <button
          onClick={reload}
          style={{
            padding: "10px 12px",
            borderRadius: 12,
            border: "1px solid #e5e7eb",
            background: "#fff",
            cursor: "pointer",
            fontWeight: 800,
          }}
        >
          Reload
        </button>
      </div>
    </div>
  );
}
