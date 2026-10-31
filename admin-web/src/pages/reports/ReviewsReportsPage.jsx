import React, { useState } from "react";
import { CheckCircle, Flag, XCircle } from "lucide-react";
import { RbacNoticeBanner, StatusBadge } from "../../components/CommonUI";
import { useAuth } from "../../hooks/useAuth";
import { adminApi } from "../../services/api/client";

const ISSUE_LABELS = {
  wrong_hours: "Sai giờ mở cửa / Khung giờ nghỉ",
  closed_permanently: "Đã đóng cửa vĩnh viễn",
  wrong_location: "Sai vị trí / Địa chỉ bản đồ",
  wrong_price: "Thay đổi giá vé / Khoảng giá món",
  review_feedback: "Đánh giá & Góp ý trải nghiệm",
};

export default function ReviewsReportsPage({ reports, onRefresh, showToast }) {
  const { user, canModerateReports } = useAuth();
  const [statusFilter, setStatusFilter] = useState("all");
  const [noteMap, setNoteMap] = useState({});

  const filteredReports = reports.filter(
    (r) => statusFilter === "all" || r.status === statusFilter
  );

  const handleResolve = async (report, nextStatus) => {
    if (!canModerateReports()) {
      showToast("Vai trò của bạn không có quyền duyệt báo cáo sai thông tin.", "error");
      return;
    }
    const note =
      noteMap[report.id] ||
      (nextStatus === "resolved"
        ? "Moderator đã xác minh thực tế và cập nhật thông tin trên hệ thống."
        : "Báo cáo chưa đủ cơ sở xác thực.");

    try {
      await adminApi.resolveReport(
        report.id,
        {
          status: nextStatus,
          moderator_note: note,
        },
        user
      );
      showToast(
        `Đã ${nextStatus === "resolved" ? "duyệt & xử lý" : "từ chối"} báo cáo #${report.id}`
      );
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  return (
    <div>
      <RbacNoticeBanner role={user?.role} assignedProvinceId={user?.assigned_province_id} />

      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-xl font-extrabold text-slate-900 flex items-center gap-2">
            <Flag className="w-6 h-6 text-rose-600" />
            Kiểm Duyệt Đánh Giá & Báo Cáo Sai Thông Tin ({filteredReports.length})
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Tiếp nhận phản hồi của du khách từ ứng dụng (sai giờ mở cửa, đổi giá, đổi địa chỉ...)
            để đảm bảo dữ liệu luôn chính xác.
          </p>
        </div>

        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="text-xs font-semibold border border-slate-300 rounded-xl px-3 py-2 bg-white"
        >
          <option value="all">Tất cả trạng thái</option>
          <option value="pending">Đang chờ duyệt (pending)</option>
          <option value="resolved">Đã xử lý (resolved)</option>
          <option value="rejected">Đã từ chối (rejected)</option>
        </select>
      </div>

      <div className="space-y-4">
        {filteredReports.map((rep) => (
          <div
            key={rep.id}
            className="bg-white rounded-2xl border border-slate-200 p-5 shadow-xs flex flex-col lg:flex-row lg:items-center justify-between gap-4"
          >
            <div className="space-y-1.5 flex-1">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="font-mono text-xs font-bold text-slate-400">#{rep.id}</span>
                <span className="px-2.5 py-0.5 rounded-md bg-slate-100 text-slate-800 text-xs font-bold uppercase">
                  {rep.target_type}
                </span>
                <span className="text-sm font-extrabold text-slate-900">{rep.target_name}</span>
                <span className="px-2.5 py-0.5 rounded-md bg-rose-50 text-rose-700 border border-rose-200 text-xs font-semibold">
                  {ISSUE_LABELS[rep.issue_type] || rep.issue_type}
                </span>
                <StatusBadge status={rep.status} />
              </div>

              <p className="text-xs text-slate-700 bg-slate-50 p-3 rounded-xl border border-slate-200/80">
                "{rep.description}"
              </p>

              {rep.moderator_note && (
                <p className="text-xs text-teal-800 bg-teal-50/70 px-3 py-2 rounded-xl border border-teal-200">
                  <strong>Ghi chú Kiểm duyệt viên:</strong> {rep.moderator_note}
                </p>
              )}
            </div>

            {rep.status === "pending" && canModerateReports() && (
              <div className="w-full lg:w-80 space-y-2 shrink-0 border-t lg:border-t-0 lg:border-l border-slate-100 pt-3 lg:pt-0 lg:pl-4">
                <input
                  type="text"
                  placeholder="Nhập ghi chú xử lý / xác minh..."
                  value={noteMap[rep.id] || ""}
                  onChange={(e) => setNoteMap({ ...noteMap, [rep.id]: e.target.value })}
                  className="w-full px-3 py-2 text-xs border border-slate-300 rounded-xl"
                />
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => handleResolve(rep, "resolved")}
                    className="flex-1 inline-flex items-center justify-center gap-1.5 py-2 px-3 rounded-xl bg-teal-600 hover:bg-teal-700 text-white text-xs font-bold"
                  >
                    <CheckCircle className="w-4 h-4" />
                    Duyệt & Cập nhật
                  </button>
                  <button
                    type="button"
                    onClick={() => handleResolve(rep, "rejected")}
                    className="inline-flex items-center justify-center gap-1 py-2 px-3 rounded-xl bg-rose-50 hover:bg-rose-100 text-rose-700 text-xs font-bold"
                  >
                    <XCircle className="w-4 h-4" />
                    Từ chối
                  </button>
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
