import React from "react";
import {
  AlertTriangle,
  Award,
  CheckCircle2,
  Database,
  Globe,
  Handshake,
  ShieldAlert,
  X,
} from "lucide-react";

/**
 * Thẻ thống kê KPI trên Dashboard
 */
export function StatCard({ title, value, subtitle, icon: Icon, colorClass = "bg-teal-600" }) {
  return (
    <div className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">{title}</p>
          <h3 className="text-2xl font-extrabold text-slate-900 mt-1">{value}</h3>
          {subtitle && <p className="text-xs text-slate-500 mt-1.5">{subtitle}</p>}
        </div>
        {Icon && (
          <div className={`${colorClass} text-white p-3 rounded-xl shadow-sm`}>
            <Icon className="w-5 h-5" />
          </div>
        )}
      </div>
    </div>
  );
}

/**
 * Nhãn hiển thị Nguồn dữ liệu minh bạch (Mục 11 - Chính sách dữ liệu và bản quyền)
 */
export function DataSourceBadge({ source }) {
  const config = {
    internal: {
      label: "Nội bộ xác thực",
      cls: "bg-emerald-50 text-emerald-700 border-emerald-200",
      icon: CheckCircle2,
    },
    partner: {
      label: "Đối tác cung cấp",
      cls: "bg-indigo-50 text-indigo-700 border-indigo-200",
      icon: Handshake,
    },
    api_provider: {
      label: "API Bên thứ ba",
      cls: "bg-amber-50 text-amber-700 border-amber-200",
      icon: Globe,
    },
  }[source || "internal"] || {
    label: source || "Nội bộ",
    cls: "bg-slate-100 text-slate-700 border-slate-200",
    icon: Database,
  };

  const IconComp = config.icon;
  return (
    <span
      className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium border ${config.cls}`}
    >
      <IconComp className="w-3.5 h-3.5" />
      {config.label}
    </span>
  );
}

/**
 * Nhãn hiển thị nội dung Được tài trợ (Mục 12 - Chính sách quảng cáo minh bạch)
 */
export function SponsoredBadge({ label }) {
  return (
    <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-100 text-amber-800 border border-amber-300">
      <Award className="w-3.5 h-3.5 text-amber-600" />
      {label || "Được tài trợ"}
    </span>
  );
}

/**
 * Nhãn trạng thái xuất bản
 */
export function StatusBadge({ status }) {
  const styles = {
    published: "bg-teal-50 text-teal-700 border-teal-200",
    active: "bg-teal-50 text-teal-700 border-teal-200",
    resolved: "bg-teal-50 text-teal-700 border-teal-200",
    draft: "bg-amber-50 text-amber-700 border-amber-200",
    pending: "bg-amber-50 text-amber-700 border-amber-200",
    hidden: "bg-slate-100 text-slate-600 border-slate-300",
    rejected: "bg-rose-50 text-rose-700 border-rose-200",
  };
  const labels = {
    published: "Đang hiển thị",
    active: "Đang hoạt động",
    resolved: "Đã duyệt & xử lý",
    draft: "Bản nháp",
    pending: "Chờ kiểm duyệt",
    hidden: "Đã ẩn",
    rejected: "Đã từ chối",
  };
  return (
    <span
      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold border ${
        styles[status] || styles.published
      }`}
    >
      {labels[status] || status}
    </span>
  );
}

/**
 * Hộp thoại xác nhận trước khi xóa (Giảm thiểu rủi ro Admin thao tác nhầm - Mục 16)
 */
export function ConfirmDeleteModal({ isOpen, title, itemName, onConfirm, onCancel }) {
  if (!isOpen) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
      <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200">
        <div className="flex items-center gap-3 text-rose-600 mb-3">
          <div className="p-2.5 rounded-full bg-rose-100">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <h3 className="text-lg font-bold text-slate-900">{title || "Xác nhận xóa dữ liệu"}</h3>
        </div>
        <p className="text-sm text-slate-600 leading-relaxed">
          Bạn có chắc chắn muốn xóa <strong className="text-slate-900">"{itemName}"</strong> khỏi hệ
          thống? Thao tác này sẽ được ghi nhận vào <strong>Audit Logs</strong>. Khuyến nghị chuyển
          sang trạng thái <em>"Đã ẩn"</em> nếu chỉ muốn tạm ngừng hiển thị trên ứng dụng.
        </p>
        <div className="flex justify-end gap-3 mt-6">
          <button
            type="button"
            onClick={onCancel}
            className="px-4 py-2 rounded-lg text-sm font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 transition-colors"
          >
            Hủy bỏ
          </button>
          <button
            type="button"
            onClick={onConfirm}
            className="px-4 py-2 rounded-lg text-sm font-semibold text-white bg-rose-600 hover:bg-rose-700 transition-colors shadow-sm"
          >
            Xác nhận xóa
          </button>
        </div>
      </div>
    </div>
  );
}

/**
 * Khung Modal chuẩn dùng cho các Form Thêm / Chỉnh sửa
 */
export function ModalDialog({ isOpen, title, subtitle, onClose, children, maxWidth = "max-w-2xl" }) {
  if (!isOpen) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4 overflow-y-auto">
      <div
        className={`bg-white rounded-2xl w-full ${maxWidth} shadow-2xl border border-slate-200 overflow-hidden my-8`}
      >
        <div className="flex items-center justify-between px-6 py-4 bg-slate-900 text-white">
          <div>
            <h3 className="text-lg font-bold">{title}</h3>
            {subtitle && <p className="text-xs text-slate-300 mt-0.5">{subtitle}</p>}
          </div>
          <button
            type="button"
            onClick={onClose}
            className="text-slate-400 hover:text-white p-1.5 rounded-lg hover:bg-slate-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="p-6 max-h-[80vh] overflow-y-auto">{children}</div>
      </div>
    </div>
  );
}

/**
 * Banner cảnh báo giới hạn quyền RBAC
 */
export function RbacNoticeBanner({ role, assignedProvinceId }) {
  if (role === "super_admin" || role === "content_admin") return null;
  return (
    <div className="mb-5 flex items-center gap-3 px-4 py-3 rounded-xl bg-amber-50 border border-amber-200 text-amber-900 text-sm">
      <ShieldAlert className="w-5 h-5 text-amber-600 shrink-0" />
      <div>
        {role === "province_editor" ? (
          <span>
            <strong>Chế độ Biên tập viên theo Tỉnh (RBAC):</strong> Bạn chỉ được phép Tạo mới và
            Chỉnh sửa dữ liệu thuộc <strong>TP. Hồ Chí Minh (province_id = {assignedProvinceId})</strong>. Các tỉnh/thành khác ở chế độ chỉ xem.
          </span>
        ) : (
          <span>
            <strong>Chế độ Kiểm duyệt viên (Moderator):</strong> Bạn có quyền xử lý đánh giá và báo
            cáo sai thông tin. Các danh mục nội dung khác ở chế độ chỉ xem.
          </span>
        )}
      </div>
    </div>
  );
}
