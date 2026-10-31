import React from "react";
import {
  Activity,
  Award,
  CheckCircle2,
  Flag,
  Map,
  MapPin,
  Route,
  ShieldCheck,
  Soup,
  UtensilsCrossed,
} from "lucide-react";
import { DataSourceBadge, StatCard } from "../../components/CommonUI";

export default function DashboardPage({ snapshot, setActiveTab }) {
  const dash = snapshot.dashboard || {};
  const quota = dash.maps_api_quota || {
    provider: "osm_proxy",
    daily_calls_used: 18,
    daily_budget_limit: 500,
    usage_percentage: 3.6,
    cache_hits: 42,
    max_corridor_radius_km: 10.0,
    max_itinerary_stops: 20,
    server_key_protected: true,
  };
  const breakdown = dash.data_source_breakdown || {
    internal: 14,
    partner: 2,
    api_provider: 0,
  };
  const recentLogs = snapshot.auditLogs?.slice(0, 8) || [];

  return (
    <div className="space-y-6">
      {/* Banner tiêu điểm TP. Hồ Chí Minh */}
      <div className="bg-gradient-to-r from-teal-700 via-teal-800 to-slate-900 rounded-2xl p-6 text-white shadow-md flex flex-col md:flex-row md:items-center md:justify-between gap-4">
        <div>
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-white/15 text-teal-200">
            <CheckCircle2 className="w-3.5 h-3.5" />
            Trọng tâm triển khai: TP. Hồ Chí Minh (HCM)
          </span>
          <h1 className="text-2xl font-extrabold mt-2">
            Trung Tâm Điều Hành Dữ Liệu Du Lịch & Ẩm Thực TripFlow
          </h1>
          <p className="text-sm text-teal-100/90 mt-1 max-w-2xl">
            Mọi cập nhật về Địa điểm, Đặc sản, Nhà hàng dọc lộ trình và Lịch trình mẫu tại đây được
            đồng bộ tức thời xuống ứng dụng di động Flutter thông qua REST API mà không cần phát hành
            lại ứng dụng.
          </p>
        </div>
        <div className="flex flex-wrap gap-2.5 shrink-0">
          <button
            type="button"
            onClick={() => setActiveTab("destinations")}
            className="px-4 py-2.5 rounded-xl bg-white text-teal-900 font-bold text-xs shadow-sm hover:bg-teal-50 transition-colors"
          >
            + Quản lý Địa điểm
          </button>
          <button
            type="button"
            onClick={() => setActiveTab("restaurants")}
            className="px-4 py-2.5 rounded-xl bg-amber-500 text-white font-bold text-xs shadow-sm hover:bg-amber-600 transition-colors"
          >
            + Quản lý Nhà hàng Lộ trình
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Tỉnh / Thành Phố"
          value={dash.total_provinces ?? snapshot.provinces.length}
          subtitle="TP. Hồ Chí Minh (Trọng tâm), Đà Nẵng, Hà Nội"
          icon={Map}
          colorClass="bg-teal-600"
        />
        <StatCard
          title="Địa điểm Du lịch"
          value={dash.total_destinations ?? snapshot.destinations.length}
          subtitle="Đã xác thực tọa độ GPS & bản quyền ảnh"
          icon={MapPin}
          colorClass="bg-blue-600"
        />
        <StatCard
          title="Đặc sản & Nhà hàng"
          value={`${dash.total_local_foods ?? snapshot.localFoods.length} món • ${
            dash.total_restaurants ?? snapshot.restaurants.length
          } quán`}
          subtitle="Sẵn sàng cho tìm kiếm hành lang lộ trình"
          icon={UtensilsCrossed}
          colorClass="bg-amber-600"
        />
        <StatCard
          title="Báo sai Chờ duyệt"
          value={dash.pending_reports ?? 0}
          subtitle={`${dash.total_templates ?? 2} lịch trình mẫu • ${
            dash.sponsored_items_count ?? 2
          } đối tác tài trợ`}
          icon={Flag}
          colorClass="bg-rose-600"
        />
      </div>

      {/* Middle Row: Data Source Transparency & Maps Cost Control */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Nguồn dữ liệu & Minh bạch bản quyền (Mục 11 & 12) */}
        <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-base font-bold text-slate-900">
                Phân Bố Nguồn Dữ Liệu & Chính Sách Minh Bạch
              </h3>
              <p className="text-xs text-slate-500 mt-0.5">
                Tuân thủ Mục 11 (Bản quyền dữ liệu) & Mục 12 (Nhãn tài trợ minh bạch)
              </p>
            </div>
            <Award className="w-5 h-5 text-teal-600" />
          </div>

          <div className="space-y-4 mt-4">
            <div className="flex items-center justify-between p-3.5 rounded-xl bg-slate-50 border border-slate-200/80">
              <div className="flex items-center gap-3">
                <DataSourceBadge source="internal" />
                <span className="text-xs text-slate-600">
                  Do Ban Biên Tập TripFlow khảo sát & xác thực thực địa
                </span>
              </div>
              <span className="text-sm font-extrabold text-slate-900">
                {breakdown.internal} bản ghi
              </span>
            </div>

            <div className="flex items-center justify-between p-3.5 rounded-xl bg-slate-50 border border-slate-200/80">
              <div className="flex items-center gap-3">
                <DataSourceBadge source="partner" />
                <span className="text-xs text-slate-600">
                  Do Đối tác / Nhà tài trợ cung cấp (Có gắn nhãn công khai)
                </span>
              </div>
              <span className="text-sm font-extrabold text-slate-900">
                {breakdown.partner} bản ghi
              </span>
            </div>

            <div className="flex items-center justify-between p-3.5 rounded-xl bg-slate-50 border border-slate-200/80">
              <div className="flex items-center gap-3">
                <DataSourceBadge source="api_provider" />
                <span className="text-xs text-slate-600">
                  Đồng bộ từ dịch vụ bản đồ / Cổng dữ liệu mở
                </span>
              </div>
              <span className="text-sm font-extrabold text-slate-900">
                {breakdown.api_provider} bản ghi
              </span>
            </div>
          </div>
        </div>

        {/* Kiểm soát chi phí dịch vụ Bản đồ & Định tuyến (Mục 13.2) */}
        <div className="lg:col-span-6 bg-white rounded-2xl border border-slate-200 p-6 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-base font-bold text-slate-900">
                Giám Sát Ngân Sách & Bảo Mật API Bản Đồ (Mục 13.2)
              </h3>
              <p className="text-xs text-slate-500 mt-0.5">
                Kiểm soát tần suất gọi Directions/Corridor Search & bảo vệ khóa bí mật ở Server
              </p>
            </div>
            <ShieldCheck className="w-5 h-5 text-emerald-600" />
          </div>

          <div className="mt-3">
            <div className="flex items-center justify-between text-xs font-semibold mb-1.5">
              <span className="text-slate-600">
                Hạn mức truy vấn tuyến đường hôm nay ({quota.daily_calls_used} /{" "}
                {quota.daily_budget_limit} lượt)
              </span>
              <span className="text-teal-700 font-bold">{quota.usage_percentage}%</span>
            </div>
            <div className="w-full h-2.5 bg-slate-100 rounded-full overflow-hidden">
              <div
                className="h-full bg-teal-600 rounded-full transition-all"
                style={{ width: `${Math.min(100, quota.usage_percentage || 5)}%` }}
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3 mt-5 text-xs">
            <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
              <span className="text-slate-500 block">Bán kính Corridor tối đa</span>
              <strong className="text-slate-900 text-sm">
                {quota.max_corridor_radius_km} km quanh tuyến
              </strong>
            </div>
            <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
              <span className="text-slate-500 block">Giới hạn điểm dừng / lịch trình</span>
              <strong className="text-slate-900 text-sm">
                Tối đa {quota.max_itinerary_stops} điểm dừng
              </strong>
            </div>
            <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
              <span className="text-slate-500 block">Lượt tái sử dụng Route Cache</span>
              <strong className="text-emerald-700 text-sm">{quota.cache_hits} lượt (Tiết kiệm)</strong>
            </div>
            <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
              <span className="text-slate-500 block">Bảo vệ Server API Key</span>
              <strong className="text-emerald-700 text-sm">Đã ẩn hoàn toàn khỏi App</strong>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Audit Logs */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Activity className="w-5 h-5 text-teal-600" />
            <h3 className="text-base font-bold text-slate-900">
              Nhật Ký Thao Tác Quản Trị Gần Nhất (Audit Logs)
            </h3>
          </div>
          <button
            type="button"
            onClick={() => setActiveTab("settings")}
            className="text-xs font-semibold text-teal-600 hover:text-teal-800"
          >
            Xem toàn bộ nhật ký →
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-sm">
            <thead>
              <tr className="border-b border-slate-200 text-xs uppercase text-slate-500">
                <th className="py-2.5 px-3">Thời gian</th>
                <th className="py-2.5 px-3">Người thực hiện</th>
                <th className="py-2.5 px-3">Vai trò</th>
                <th className="py-2.5 px-3">Hành động</th>
                <th className="py-2.5 px-3">Đối tượng</th>
                <th className="py-2.5 px-3">Nội dung chi tiết</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs">
              {recentLogs.map((log) => (
                <tr key={log.id} className="hover:bg-slate-50">
                  <td className="py-2.5 px-3 text-slate-500 whitespace-nowrap">
                    {log.created_at ? new Date(log.created_at).toLocaleString("vi-VN") : "Vừa xong"}
                  </td>
                  <td className="py-2.5 px-3 font-semibold text-slate-800">{log.actor_email}</td>
                  <td className="py-2.5 px-3">
                    <span className="px-2 py-0.5 rounded-md bg-slate-100 text-slate-700 font-medium">
                      {log.actor_role}
                    </span>
                  </td>
                  <td className="py-2.5 px-3">
                    <span
                      className={`px-2 py-0.5 rounded-md font-bold ${
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
                  <td className="py-2.5 px-3 text-slate-600 font-medium">{log.entity_type}</td>
                  <td className="py-2.5 px-3 text-slate-700">{log.summary}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
