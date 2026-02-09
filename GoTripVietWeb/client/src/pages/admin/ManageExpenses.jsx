import React, { useEffect, useMemo, useState } from "react";
import CrudTable from "../../components/admin/CrudTable";
import {
  STORE_KEY,
  getList,
  addItem,
  updateItem,
  deleteItem,
} from "../../data/adminStore";

function Card({ title, value, sub }) {
  return (
    <div
      style={{
        background: "#fff",
        border: "1px solid #e5e7eb",
        borderRadius: 16,
        padding: 16,
      }}
    >
      <div style={{ color: "#6b7280", fontWeight: 800, fontSize: 12 }}>
        {title}
      </div>
      <div style={{ fontWeight: 900, fontSize: 22, marginTop: 6 }}>{value}</div>
      {sub ? <div style={{ color: "#6b7280", marginTop: 6 }}>{sub}</div> : null}
    </div>
  );
}

export default function ManageExpenses() {
  const [rows, setRows] = useState([]);
  const reload = () => setRows(getList(STORE_KEY.expenses));
  useEffect(() => reload(), []);

  const stats = useMemo(() => {
    const total = rows.reduce((s, x) => s + Number(x.amount || 0), 0);
    const approved = rows
      .filter((x) => x.status === "APPROVED")
      .reduce((s, x) => s + Number(x.amount || 0), 0);
    const pending = rows
      .filter((x) => x.status === "PENDING")
      .reduce((s, x) => s + Number(x.amount || 0), 0);
    const byCat = {};
    rows.forEach((x) => {
      const c = x.category || "Other";
      byCat[c] = (byCat[c] || 0) + Number(x.amount || 0);
    });
    const topCat = Object.entries(byCat).sort((a, b) => b[1] - a[1])[0];
    return { total, approved, pending, topCat };
  }, [rows]);

  return (
    <div style={{ display: "grid", gap: 14 }}>
      <div>
        <div style={{ fontWeight: 900, fontSize: 22 }}>Quản lý chi tiêu</div>
        <div style={{ color: "#6b7280" }}>
          Có dashboard cơ bản + nâng cao (tóm tắt theo category).
        </div>
      </div>

      {/* Dashboard cơ bản */}
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(3, 1fr)",
          gap: 12,
        }}
      >
        <Card
          title="Tổng chi"
          value={stats.total.toLocaleString("vi-VN")}
          sub="VND"
        />
        <Card
          title="Đã duyệt"
          value={stats.approved.toLocaleString("vi-VN")}
          sub="VND"
        />
        <Card
          title="Chờ duyệt"
          value={stats.pending.toLocaleString("vi-VN")}
          sub="VND"
        />
      </div>

      {/* Dashboard nâng cao */}
      <div
        style={{
          background: "#fff",
          border: "1px solid #e5e7eb",
          borderRadius: 16,
          padding: 16,
        }}
      >
        <div style={{ fontWeight: 900, marginBottom: 8 }}>
          Dashboard nâng cao
        </div>
        <div style={{ color: "#6b7280" }}>
          Category top: <b>{stats.topCat?.[0] || "—"}</b> (
          {(stats.topCat?.[1] || 0).toLocaleString("vi-VN")} VND)
        </div>
      </div>

      <CrudTable
        title="Danh sách chi tiêu"
        data={rows}
        schema={[
          { key: "id", label: "ID", type: "text" },
          { key: "date", label: "Ngày", type: "text" },
          { key: "category", label: "Danh mục", type: "text" },
          { key: "amount", label: "Số tiền", type: "number" },
          { key: "note", label: "Ghi chú", type: "text" },
          { key: "status", label: "Status", type: "text" },
        ]}
        onAdd={(item) => {
          addItem(STORE_KEY.expenses, item);
          reload();
        }}
        onUpdate={(id, patch) => {
          updateItem(STORE_KEY.expenses, id, patch);
          reload();
        }}
        onDelete={(id) => {
          deleteItem(STORE_KEY.expenses, id);
          reload();
        }}
        onToggleStatus={(id, current) => {
          const next = current === "APPROVED" ? "PENDING" : "APPROVED";
          updateItem(STORE_KEY.expenses, id, { status: next });
          reload();
        }}
        statusKey="status"
      />
    </div>
  );
}
