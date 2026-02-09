// ManageAdmins.jsx
import React, { useEffect, useState } from "react";
import CrudTable from "../../components/admin/CrudTable";
import userApi from "../../api/userApi";
import authApi from "../../api/authApi";

export default function ManageAdmins() {
  const [rows, setRows] = useState([]);

  const mapRow = (u) => ({
    id: u._id || u.id,
    fullName: u.fullName || "",
    email: u.email || "",
    phone: u.phone || "",
    role: (u.roles || []).includes("admin") ? "admin" : "user",
    status: u.status || "ACTIVE",
    createdAt: u.createdAt ? new Date(u.createdAt).toLocaleString() : "",
  });

  const reload = async () => {
    const res = await userApi.getAll({ page: 1, limit: 1000 });
    const admins = (res.users || [])
      .filter((u) => Array.isArray(u.roles) && u.roles.includes("admin"))
      .map(mapRow);
    setRows(admins);
  };

  useEffect(() => {
    reload();
  }, []);

  return (
    <div style={{ display: "grid", gap: 14 }}>
      <div>
        <div style={{ fontWeight: 900, fontSize: 22 }}>Quản lý admin</div>
        <div style={{ color: "#6b7280" }}>CRUD + trạng thái + role.</div>
      </div>

      <CrudTable
        title="Admins"
        data={rows}
        schema={[
          { key: "id", label: "ID", type: "text", hideOnForm: true },
          { key: "fullName", label: "Họ tên", type: "text" },
          { key: "email", label: "Email", type: "text" },
          { key: "phone", label: "SĐT", type: "text" },

          {
            key: "role",
            label: "Role",
            type: "select",
            options: [
              { label: "Admin", value: "admin" },
              { label: "User", value: "user" },
            ],
          },
          {
            key: "createdAt",
            label: "Ngày tạo",
            type: "text",
            hideOnForm: true,
          },
        ]}
        onAdd={async (item) => {
          const reg = await authApi.register({
            email: item.email,
            password: item.password || "123456",
            fullName: item.fullName,
          });

          const newUserId = reg?.user?._id || reg?.user?.id;
          if (!newUserId) throw new Error("Không lấy được user id");

          if (item.role) await userApi.updateRole(newUserId, [item.role]);
          if (item.status) await userApi.updateStatus(newUserId, item.status);

          await reload();
        }}
        onUpdate={async (id, patch) => {
          await userApi.updateById(id, {
            fullName: patch.fullName,
            phone: patch.phone,
          });
          if (patch.role) await userApi.updateRole(id, [patch.role]);
          if (patch.status) await userApi.updateStatus(id, patch.status);
          await reload();
        }}
        onDelete={async (id) => {
          await userApi.deleteById(id);
          await reload();
        }}
        onToggleStatus={async (id, currentStatus) => {
          const next = currentStatus === "ACTIVE" ? "LOCKED" : "ACTIVE";
          await userApi.updateStatus(id, next);
          await reload();
        }}
        statusKey="status"
      />
    </div>
  );
}
