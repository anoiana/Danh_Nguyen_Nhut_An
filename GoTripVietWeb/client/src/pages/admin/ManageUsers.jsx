// ManageUsers.jsx
import React, { useEffect, useState } from "react";
import CrudTable from "../../components/admin/CrudTable";
import userApi from "../../api/userApi";
import authApi from "../../api/authApi";

export default function ManageUsers() {
  const [rows, setRows] = useState([]);

  const mapRow = (u) => ({
    id: u._id || u.id,
    fullName: u.fullName || "",
    email: u.email || "",
    phone: u.phone || "",
    role: (u.roles || []).includes("admin") ? "admin" : "user", // ✅ 1 chọn
    status: u.status || "ACTIVE", // ✅ hiện status
    createdAt: u.createdAt ? new Date(u.createdAt).toLocaleString() : "",
  });

  const reload = async () => {
    const res = await userApi.getAll({ page: 1, limit: 1000 });
    const users = (res.users || [])
      .filter(
        (u) =>
          Array.isArray(u.roles) &&
          u.roles.includes("user") &&
          !u.roles.includes("admin")
      )
      .map(mapRow);

    setRows(users);
  };

  useEffect(() => {
    reload();
  }, []);

  return (
    <div style={{ display: "grid", gap: 14 }}>
      <div>
        <div style={{ fontWeight: 900, fontSize: 22 }}>Quản lý người dùng</div>
        <div style={{ color: "#6b7280" }}>CRUD + khóa/mở tài khoản.</div>
      </div>

      <CrudTable
        title="Users"
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
              { label: "User", value: "user" },
              { label: "Admin", value: "admin" },
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
          // 1) register tạo user
          const reg = await authApi.register({
            email: item.email,
            password: item.password || "123456",
            fullName: item.fullName,
          });

          const newUserId = reg?.user?._id || reg?.user?.id;

          // 2) set role (1 trong 2)
          if (newUserId && item.role) {
            await userApi.updateRole(newUserId, [item.role]);
          }

          // 3) set status (nếu bạn đã làm endpoint /users/:id/status)
          if (newUserId && item.status) {
            await userApi.updateStatus(newUserId, item.status);
          }

          await reload();
        }}
        onUpdate={async (id, patch) => {
          // update info cơ bản
          await userApi.updateById(id, {
            fullName: patch.fullName,
            phone: patch.phone,
          });

          // ✅ update role nếu có
          if (patch.role) {
            await userApi.updateRole(id, [patch.role]); // role 1 lựa chọn
          }

          // ✅ update status nếu có
          if (patch.status) {
            await userApi.updateStatus(id, patch.status);
          }

          await reload();
        }}
        onDelete={async (id) => {
          await userApi.deleteById(id);
          await reload();
        }}
        onToggleStatus={async (id, currentStatus) => {
          // nếu CrudTable truyền vào được id + currentStatus thì toggle nhanh
          const next = currentStatus === "ACTIVE" ? "BANNED" : "ACTIVE";
          await userApi.updateStatus(id, next);
          await reload();
        }}
        statusKey="status"
      />
    </div>
  );
}
