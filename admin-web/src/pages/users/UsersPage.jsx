import React, { useState } from "react";
import { Lock, Shield, Unlock, Users } from "lucide-react";
import { ModalDialog, RbacNoticeBanner } from "../../components/CommonUI";
import { useAuth } from "../../hooks/useAuth";
import { adminApi } from "../../services/api/client";

export default function UsersPage({ users, provinces, onRefresh, showToast }) {
  const { user, canManageUsers } = useAuth();
  const [editingUser, setEditingUser] = useState(null);
  const [roleForm, setRoleForm] = useState({
    role: "user",
    assigned_province_id: null,
    is_active: true,
  });

  const openRoleModal = (targetUser) => {
    setEditingUser(targetUser);
    setRoleForm({
      role: targetUser.role,
      assigned_province_id: targetUser.assigned_province_id || "",
      is_active: targetUser.is_active,
    });
  };

  const handleSaveRole = async (e) => {
    e.preventDefault();
    if (!editingUser) return;
    try {
      await adminApi.updateUserRole(
        editingUser.id,
        {
          role: roleForm.role,
          assigned_province_id:
            roleForm.role === "province_editor" && roleForm.assigned_province_id
              ? Number(roleForm.assigned_province_id)
              : null,
          is_active: Boolean(roleForm.is_active),
        },
        user
      );
      showToast(`Đã cập nhật quyền RBAC cho ${editingUser.email}`);
      setEditingUser(null);
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  const handleToggleLock = async (targetUser) => {
    if (!canManageUsers()) {
      showToast("Chỉ Super Admin mới có quyền khóa/mở khóa tài khoản.", "error");
      return;
    }
    try {
      await adminApi.updateUserRole(
        targetUser.id,
        {
          role: targetUser.role,
          assigned_province_id: targetUser.assigned_province_id,
          is_active: !targetUser.is_active,
        },
        user
      );
      showToast(
        `Đã ${!targetUser.is_active ? "mở khóa" : "khóa"} tài khoản ${targetUser.email}`
      );
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  return (
    <div>
      <RbacNoticeBanner role={user?.role} assignedProvinceId={user?.assigned_province_id} />

      <div className="mb-6">
        <h1 className="text-xl font-extrabold text-slate-900 flex items-center gap-2">
          <Users className="w-6 h-6 text-teal-600" />
          Quản Lý Tài Khoản Người Dùng & Phân Quyền RBAC ({users.length})
        </h1>
        <p className="text-xs text-slate-500 mt-1">
          Xem danh sách người dùng và nhân sự quản trị, khóa/mở khóa tài khoản, phân quyền vai trò
          và gán phạm vi Tỉnh/Thành phụ trách.
        </p>
      </div>

      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold uppercase text-slate-500">
                <th className="py-3.5 px-4">ID</th>
                <th className="py-3.5 px-4">Họ và tên & Email</th>
                <th className="py-3.5 px-4">Vai trò RBAC</th>
                <th className="py-3.5 px-4">Phạm vi Tỉnh phụ trách</th>
                <th className="py-3.5 px-4">Trạng thái</th>
                <th className="py-3.5 px-4 text-right">Thao tác (Super Admin)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs">
              {users.map((u) => {
                const assignedProv = provinces.find(
                  (p) => Number(p.id) === Number(u.assigned_province_id)
                );

                return (
                  <tr key={u.id} className="hover:bg-slate-50">
                    <td className="py-3.5 px-4 font-mono text-slate-500">#{u.id}</td>
                    <td className="py-3.5 px-4">
                      <span className="font-bold text-slate-900 block">{u.full_name}</span>
                      <span className="text-[11px] text-slate-500">{u.email}</span>
                    </td>
                    <td className="py-3.5 px-4">
                      <span
                        className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full font-bold text-[11px] ${
                          u.role === "super_admin"
                            ? "bg-teal-100 text-teal-800"
                            : u.role === "content_admin"
                            ? "bg-blue-100 text-blue-800"
                            : u.role === "province_editor"
                            ? "bg-amber-100 text-amber-800"
                            : u.role === "moderator"
                            ? "bg-purple-100 text-purple-800"
                            : "bg-slate-100 text-slate-700"
                        }`}
                      >
                        <Shield className="w-3 h-3" />
                        {u.role}
                      </span>
                    </td>
                    <td className="py-3.5 px-4">
                      {u.role === "province_editor" ? (
                        <span className="font-semibold text-amber-700">
                          {assignedProv ? `${assignedProv.name} (${assignedProv.code})` : "Chưa gán"}
                        </span>
                      ) : u.role === "user" ? (
                        <span className="text-slate-400">Người dùng App</span>
                      ) : (
                        <span className="text-teal-700 font-semibold">Toàn hệ thống</span>
                      )}
                    </td>
                    <td className="py-3.5 px-4">
                      <span
                        className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                          u.is_active
                            ? "bg-emerald-50 text-emerald-700 border border-emerald-200"
                            : "bg-rose-50 text-rose-700 border border-rose-200"
                        }`}
                      >
                        {u.is_active ? "Đang hoạt động" : "Đã khóa"}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 text-right whitespace-nowrap">
                      {canManageUsers() ? (
                        <div className="inline-flex items-center gap-2">
                          <button
                            type="button"
                            onClick={() => openRoleModal(u)}
                            className="px-3 py-1.5 rounded-lg bg-teal-50 text-teal-700 font-bold hover:bg-teal-100"
                          >
                            Phân quyền RBAC
                          </button>
                          <button
                            type="button"
                            onClick={() => handleToggleLock(u)}
                            className="p-1.5 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200"
                            title={u.is_active ? "Khóa tài khoản" : "Mở khóa"}
                          >
                            {u.is_active ? (
                              <Lock className="w-4 h-4 text-rose-600" />
                            ) : (
                              <Unlock className="w-4 h-4 text-emerald-600" />
                            )}
                          </button>
                        </div>
                      ) : (
                        <span className="text-[11px] text-slate-400 italic">Chỉ Super Admin</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Phân Quyền */}
      <ModalDialog
        isOpen={Boolean(editingUser)}
        title={`Phân quyền RBAC: ${editingUser?.full_name}`}
        subtitle={editingUser?.email}
        onClose={() => setEditingUser(null)}
        maxWidth="max-w-md"
      >
        <form onSubmit={handleSaveRole} className="space-y-4 text-xs">
          <div>
            <label className="block font-bold text-slate-700 mb-1">Vai trò Hệ thống (Role)</label>
            <select
              value={roleForm.role}
              onChange={(e) => setRoleForm({ ...roleForm, role: e.target.value })}
              className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white"
            >
              <option value="super_admin">Super Admin (Toàn quyền hệ thống)</option>
              <option value="content_admin">Content Admin (Quản lý nội dung toàn quốc)</option>
              <option value="province_editor">Province Editor (Biên tập viên theo Tỉnh)</option>
              <option value="moderator">Moderator (Kiểm duyệt báo cáo & đánh giá)</option>
              <option value="user">User (Du khách sử dụng App)</option>
            </select>
          </div>

          {roleForm.role === "province_editor" && (
            <div>
              <label className="block font-bold text-slate-700 mb-1">
                Chọn Tỉnh / Thành phố được giao phụ trách *
              </label>
              <select
                required
                value={roleForm.assigned_province_id}
                onChange={(e) =>
                  setRoleForm({ ...roleForm, assigned_province_id: e.target.value })
                }
                className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white"
              >
                <option value="">-- Chọn tỉnh/thành --</option>
                {provinces.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name} ({p.code})
                  </option>
                ))}
              </select>
            </div>
          )}

          <div className="flex justify-end gap-2 pt-3 border-t border-slate-200">
            <button
              type="button"
              onClick={() => setEditingUser(null)}
              className="px-4 py-2 rounded-xl bg-slate-100 text-slate-700 font-bold"
            >
              Hủy
            </button>
            <button
              type="submit"
              className="px-5 py-2 rounded-xl bg-teal-600 text-white font-bold"
            >
              Lưu Phân Quyền
            </button>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
}
