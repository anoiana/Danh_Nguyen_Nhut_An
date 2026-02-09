import React, { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { STORE_KEY, getList } from "../../data/adminStore";

function Card({ title, value, sub }) {
  return (
    <div
      style={{
        background: "#fff",
        border: "1px solid #e5e7eb",
        borderRadius: 16,
        padding: 14,
      }}
    >
      <div style={{ color: "#6b7280", fontSize: 12, fontWeight: 900 }}>
        {title}
      </div>
      <div style={{ fontWeight: 900, fontSize: 22, marginTop: 6 }}>{value}</div>
      {sub ? <div style={{ color: "#6b7280", marginTop: 6 }}>{sub}</div> : null}
    </div>
  );
}

export default function ManageOrder() {
  const nav = useNavigate();
  const [hotelOrders, setHotelOrders] = useState([]);
  const [flightOrders, setFlightOrders] = useState([]);

  const reload = () => {
    setHotelOrders(getList(STORE_KEY.orders_hotels));
    setFlightOrders(getList(STORE_KEY.orders_flights));
  };

  useEffect(() => reload(), []);

  const stats = useMemo(() => {
    const all = [...hotelOrders, ...flightOrders];
    const total = all.length;
    const paid = all.filter((x) => x.paymentStatus === "PAID").length;
    const pending = all.filter((x) => x.status === "PENDING").length;
    const revenue = all
      .filter((x) => x.paymentStatus === "PAID")
      .reduce((s, x) => s + Number(x.totalAmount || 0), 0);

    const latest = all
      .slice()
      .sort((a, b) =>
        String(b.createdAt || "").localeCompare(String(a.createdAt || ""))
      )
      .slice(0, 8);

    return { total, paid, pending, revenue, latest };
  }, [hotelOrders, flightOrders]);

  return (
    <div style={{ display: "grid", gap: 14 }}>
      <div style={{ display: "flex", alignItems: "end", gap: 12 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontWeight: 900, fontSize: 22 }}>Management Order</div>
          <div style={{ color: "#6b7280" }}>
            tổng quan đơn khách sạn + chuyến bay
          </div>
        </div>

        <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
          <button
            onClick={() => nav("/admin/manage/orders/hotels")}
            style={btnPrimary}
          >
            Đơn khách sạn
          </button>
          <button
            onClick={() => nav("/admin/manage/orders/flights")}
            style={btn}
          >
            Đơn chuyến bay
          </button>
        </div>
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
          gap: 12,
        }}
      >
        <Card title="Tổng đơn" value={stats.total} />
        <Card title="Đã thanh toán" value={stats.paid} />
        <Card title="Đang chờ xử lý" value={stats.pending} />
        <Card
          title="Doanh thu (PAID)"
          value={stats.revenue.toLocaleString("vi-VN")}
          sub="VND"
        />
      </div>

      <div
        style={{
          background: "#fff",
          border: "1px solid #e5e7eb",
          borderRadius: 16,
          padding: 14,
        }}
      >
        <div style={{ fontWeight: 900, marginBottom: 10 }}>Đơn gần đây</div>
        <div style={{ overflowX: "auto" }}>
          <table
            style={{
              width: "100%",
              borderCollapse: "separate",
              borderSpacing: 0,
              tableLayout: "fixed",
            }}
          >
            <thead>
              <tr>
                <Th>#</Th>
                <Th>Type</Th>
                <Th>ID</Th>
                <Th>Khách</Th>
                <Th>Sản phẩm</Th>
                <Th>Tổng</Th>
                <Th>Pay</Th>
                <Th>Status</Th>
              </tr>
            </thead>
            <tbody>
              {stats.latest.map((x, idx) => (
                <tr key={x.id}>
                  <Td>{idx + 1}</Td>
                  <Td>{x.type}</Td>
                  <Td style={{ fontWeight: 900 }}>{x.id}</Td>
                  <Td>{x.contactEmail}</Td>
                  <Td>{x.type === "HOTEL" ? x.hotelName : x.operatedBy}</Td>
                  <Td>{Number(x.totalAmount || 0).toLocaleString("vi-VN")}</Td>
                  <Td>{x.paymentStatus}</Td>
                  <Td>{x.status}</Td>
                </tr>
              ))}
              {stats.latest.length === 0 ? (
                <tr>
                  <Td colSpan={8}>chưa có order</Td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

const btn = {
  padding: "10px 12px",
  borderRadius: 12,
  border: "1px solid #e5e7eb",
  background: "#fff",
  cursor: "pointer",
  fontWeight: 900,
};

const btnPrimary = { ...btn, border: 0, background: "#0b5fff", color: "#fff" };

const Th = (p) => (
  <th
    style={{
      textAlign: "left",
      padding: "8px 10px",
      fontSize: 11,
      color: "#6b7280",
      borderBottom: "1px solid #e5e7eb",
      whiteSpace: "nowrap",
    }}
    {...p}
  />
);
const Td = ({ style, ...p }) => (
  <td
    style={{
      padding: "8px 10px",
      borderBottom: "1px solid #f1f5f9",
      fontSize: 12,
      overflowWrap: "anywhere",
      ...style,
    }}
    {...p}
  />
);
