import React, { useState } from "react";
import { Activity, Cloud, Compass, Database, RotateCcw, ShieldCheck, Zap } from "lucide-react";
import { adminApi } from "../../services/api/client";
import { INITIAL_ADMIN_DATA } from "../../services/api/mockAdminData";

export default function SystemSettingsPage({
  auditLogs,
  roles,
  quota,
  onRefresh,
  showToast,
}) {
  const [actionFilter, setActionFilter] = useState("all");
  const permissionsList = INITIAL_ADMIN_DATA.permissions || [];

  const filteredLogs = (auditLogs || []).filter(
    (lg) => actionFilter === "all" || lg.action === actionFilter
  );

  const handleResetDemoData = () => {
    adminApi.resetLocalStore();
    showToast(
      "Đã khôi phục kho dữ liệu mẫu 10 Địa điểm TP.HCM & Đà Nẵng (SQLModel + Goong + Cloudinary)."
    );
    onRefresh();
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-extrabold text-slate-900 flex items-center gap-2">
            <ShieldCheck className="w-6 h-6 text-teal-600" />
            Quản Trị Hệ Thống, Kiến Trúc Tối Ưu, Bảng Role/Permission & Audit Logs
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Giám sát Goong Maps API, Cloudinary CDN, thuật toán Bounding Box + Shapely Corridor
            Search, Rate Limit (slowapi 10 req/phút) và bảng phân quyền RBAC chuẩn hóa.
          </p>
        </div>

        <button
          type="button"
          onClick={handleResetDemoData}
          className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-slate-200 hover:bg-slate-300 text-slate-800 text-xs font-bold"
        >
          <RotateCcw className="w-3.5 h-3.5" />
          Khôi phục Dữ liệu Mẫu Gốc (seed_db.py)
        </button>
      </div>

      {/* 5 Tối ưu kiến trúc & Phòng tránh Pitfalls */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-2xl border border-slate-200 p-4 shadow-xs">
          <div className="flex items-center gap-2 text-teal-700 font-extrabold text-xs uppercase">
            <Compass className="w-4 h-4" />
            Bản đồ & Định tuyến
          </div>
          <p className="text-sm font-extrabold text-slate-900 mt-1.5">
            Goong Maps API (goong.io)
          </p>
          <p className="text-[11px] text-slate-500 mt-1">
            Giải mã Encoded Polyline + Lọc Bounding Box SQL +{" "}
            <span className="font-semibold text-slate-700">Shapely LineString (&lt; 2km)</span>.
          </p>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 p-4 shadow-xs">
          <div className="flex items-center gap-2 text-amber-700 font-extrabold text-xs uppercase">
            <Zap className="w-4 h-4" />
            Rate Limiting (slowapi)
          </div>
          <p className="text-sm font-extrabold text-slate-900 mt-1.5">
            {quota?.corridor_rate_limit || "10/minute"} mỗi IP
          </p>
          <p className="text-[11px] text-slate-500 mt-1">
            Chống spam API tìm đường & bảo vệ hạn mức phí Goong Maps (Đã dùng:{" "}
            {quota?.daily_calls_used || 18}/{quota?.daily_budget_limit || 500} lượt/ngày).
          </p>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 p-4 shadow-xs">
          <div className="flex items-center gap-2 text-sky-700 font-extrabold text-xs uppercase">
            <Cloud className="w-4 h-4" />
            Tối ưu Ảnh (Cloudinary)
          </div>
          <p className="text-sm font-extrabold text-slate-900 mt-1.5">
            Cloudinary Image CDN
          </p>
          <p className="text-[11px] text-slate-500 mt-1">
            Thumbnail: <code className="bg-slate-100 px-1 rounded">c_fill,w_400,h_300,q_auto,f_auto</code>{" "}
            • Chi tiết: <code className="bg-slate-100 px-1 rounded">w_1200,q_auto,f_auto</code>
          </p>
        </div>

        <div className="bg-white rounded-2xl border border-slate-200 p-4 shadow-xs">
          <div className="flex items-center gap-2 text-emerald-700 font-extrabold text-xs uppercase">
            <Database className="w-4 h-4" />
            Database & ORM
          </div>
          <p className="text-sm font-extrabold text-slate-900 mt-1.5">
            PostgreSQL 15 + SQLModel
          </p>
          <p className="text-[11px] text-slate-500 mt-1">
            Bỏ PostGIS ở MVP; dùng B-Tree Composite Index trên{" "}
            <code className="bg-slate-100 px-1 rounded">(latitude, longitude)</code>.
          </p>
        </div>
      </div>

      {/* RBAC Matrix Table (Role & Permission Tables - Pitfall #2) */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs space-y-5">
        <div>
          <h3 className="text-base font-extrabold text-slate-900">
            Bảng Vai Trò (`roles`) & Quyền Hạn Chi Tiết (`permissions` / `role_permission_links`)
          </h3>
          <p className="text-xs text-slate-500 mt-0.5">
            Thiết kế chuẩn RBAC bằng SQLModel cho phép cấp/thu hồi từng quyền nhỏ mà không cần sửa
            code kiểm tra cứng.
          </p>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 uppercase">
                <th className="py-2.5 px-3">Mã vai trò (Role Code)</th>
                <th className="py-2.5 px-3">Tên vai trò</th>
                <th className="py-2.5 px-3">Mô tả phạm vi quyền hạn</th>
                <th className="py-2.5 px-3">Danh sách Permissions (SQLModel Link)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {(roles || []).map((r) => (
                <tr key={r.id}>
                  <td className="py-2.5 px-3 font-mono font-bold text-teal-700">{r.role_code}</td>
                  <td className="py-2.5 px-3 font-bold text-slate-900">{r.role_name}</td>
                  <td className="py-2.5 px-3 text-slate-600">{r.description}</td>
                  <td className="py-2.5 px-3">
                    <div className="flex flex-wrap gap-1">
                      {(r.permissions || []).map((perm) => (
                        <span
                          key={perm}
                          className="px-2 py-0.5 rounded bg-teal-50 text-teal-800 border border-teal-200 font-mono text-[10px] font-semibold"
                        >
                          {perm}
                        </span>
                      ))}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="pt-2 border-t border-slate-100">
          <h4 className="text-xs font-extrabold uppercase text-slate-500 mb-2">
            Danh mục 10 Quyền hạn Chuẩn trong Bảng `permissions`
          </h4>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-2">
            {permissionsList.map((p) => (
              <div
                key={p.id}
                className="p-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs"
              >
                <span className="font-mono font-bold text-teal-700 block">{p.code}</span>
                <span className="text-slate-700 font-semibold text-[11px]">{p.name}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Full Audit Logs */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
          <div className="flex items-center gap-2">
            <Activity className="w-5 h-5 text-teal-600" />
            <h3 className="text-base font-extrabold text-slate-900">
              Nhật Ký Thao Tác Hệ Thống (Audit Logs — {filteredLogs.length} bản ghi)
            </h3>
          </div>

          <select
            value={actionFilter}
            onChange={(e) => setActionFilter(e.target.value)}
            className="text-xs font-semibold border border-slate-300 rounded-xl px-3 py-1.5 bg-white"
          >
            <option value="all">Tất cả hành động</option>
            <option value="CREATE">CREATE (Tạo mới)</option>
            <option value="UPDATE">UPDATE (Cập nhật)</option>
            <option value="DELETE">DELETE (Xóa)</option>
            <option value="UPLOAD">UPLOAD (Cloudinary CDN)</option>
            <option value="APPROVE">APPROVE (Duyệt báo cáo)</option>
            <option value="LOGIN">LOGIN (Đăng nhập)</option>
          </select>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 uppercase">
                <th className="py-2.5 px-3">ID</th>
                <th className="py-2.5 px-3">Thời gian</th>
                <th className="py-2.5 px-3">Tài khoản thực hiện</th>
                <th className="py-2.5 px-3">Role</th>
                <th className="py-2.5 px-3">Action</th>
                <th className="py-2.5 px-3">Entity</th>
                <th className="py-2.5 px-3">Tóm tắt nội dung</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {filteredLogs.map((log) => (
                <tr key={log.id} className="hover:bg-slate-50">
                  <td className="py-2.5 px-3 font-mono text-slate-400">#{log.id}</td>
                  <td className="py-2.5 px-3 text-slate-500 whitespace-nowrap">
                    {log.created_at
                      ? new Date(log.created_at).toLocaleString("vi-VN")
                      : "30/10/2026"}
                  </td>
                  <td className="py-2.5 px-3 font-bold text-slate-800">{log.actor_email}</td>
                  <td className="py-2.5 px-3">
                    <span className="px-2 py-0.5 rounded bg-slate-100 text-slate-700 font-semibold">
                      {log.actor_role}
                    </span>
                  </td>
                  <td className="py-2.5 px-3">
                    <span
                      className={`px-2 py-0.5 rounded font-bold ${
                        log.action === "CREATE"
                          ? "bg-emerald-100 text-emerald-800"
                          : log.action === "DELETE"
                          ? "bg-rose-100 text-rose-800"
                          : "bg-blue-100 text-blue-800"
                      }`}
                    >
                      {log.action}
                    </span>
                  </td>
                  <td className="py-2.5 px-3 font-mono text-slate-600">
                    {log.entity_type} {log.entity_id ? `(#${log.entity_id})` : ""}
                  </td>
                  <td className="py-2.5 px-3 text-slate-800">{log.summary}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
