import React from "react";
import { Award, CheckCircle2, Handshake, ShieldCheck } from "lucide-react";
import { DataSourceBadge, SponsoredBadge } from "../../components/CommonUI";
import { useAuth } from "../../hooks/useAuth";
import { adminApi } from "../../services/api/client";

export default function PartnersSponsorsPage({
  destinations,
  restaurants,
  onRefresh,
  showToast,
}) {
  const { user, canManageProvince } = useAuth();

  const toggleDestinationSponsor = async (dest) => {
    if (!canManageProvince(dest.province_id)) {
      showToast("Bạn không có quyền thay đổi trạng thái tài trợ của tỉnh này.", "error");
      return;
    }
    const nextVal = !dest.is_sponsored;
    try {
      await adminApi.saveDestination(
        {
          ...dest,
          is_sponsored: nextVal,
          sponsor_label: nextVal ? "Điểm đến Đối tác Du lịch TP.HCM" : null,
          data_source: nextVal ? "partner" : "internal",
        },
        user
      );
      showToast(
        `Đã ${nextVal ? "bật" : "tắt"} nhãn tài trợ cho địa điểm "${dest.name}"`
      );
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  const toggleRestaurantSponsor = async (rest) => {
    if (!canManageProvince(rest.province_id)) {
      showToast("Bạn không có quyền thay đổi trạng thái tài trợ của tỉnh này.", "error");
      return;
    }
    const nextVal = !rest.is_sponsored;
    try {
      await adminApi.saveRestaurant(
        {
          ...rest,
          is_sponsored: nextVal,
          sponsor_label: nextVal ? "Được tài trợ • Đối tác Ẩm thực Địa phương" : null,
          data_source: nextVal ? "partner" : "internal",
        },
        user
      );
      showToast(
        `Đã ${nextVal ? "bật" : "tắt"} nhãn tài trợ cho nhà hàng "${rest.name}"`
      );
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  return (
    <div className="space-y-6">
      <div className="bg-gradient-to-r from-indigo-900 via-slate-900 to-teal-900 text-white rounded-2xl p-6 shadow-sm">
        <div className="flex items-center gap-2 text-amber-300 text-xs font-bold uppercase tracking-wider">
          <Handshake className="w-4 h-4" />
          Chính sách Quảng cáo, Tài trợ & Thương mại Minh bạch (Mục 12)
        </div>
        <h1 className="text-xl font-extrabold mt-2">
          Quản Lý Nội Dung Đối Tác & Gắn Nhãn Tài Trợ Minh Bạch
        </h1>
        <p className="text-xs text-slate-300 mt-1 max-w-3xl leading-relaxed">
          Theo quy định tại Mục 12 của tài liệu dự án: Mọi địa điểm hoặc nhà hàng được ưu tiên hiển
          thị nhờ hợp tác thương mại bắt buộc phải gắn nhãn rõ ràng là{" "}
          <strong>"Được tài trợ"</strong> hoặc <strong>"Đối tác địa phương"</strong>, không làm sai
          lệch kết quả tìm kiếm tự nhiên và tuyệt đối không thu phí thanh toán trong ứng dụng ở
          giai đoạn MVP.
        </p>
      </div>

      {/* Sponsored Restaurants */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs">
        <h2 className="text-base font-extrabold text-slate-900 flex items-center gap-2 mb-4">
          <Award className="w-5 h-5 text-amber-600" />
          Danh sách Nhà hàng & Quán ăn Đối tác ({restaurants.filter((r) => r.is_sponsored).length}{" "}
          đang tài trợ)
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {restaurants.map((rest) => (
            <div
              key={rest.id}
              className={`p-4 rounded-xl border flex items-center justify-between gap-4 ${
                rest.is_sponsored
                  ? "bg-amber-50/40 border-amber-300"
                  : "bg-slate-50/60 border-slate-200"
              }`}
            >
              <div className="min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-sm font-bold text-slate-900">{rest.name}</span>
                  {rest.is_sponsored && <SponsoredBadge label={rest.sponsor_label} />}
                </div>
                <p className="text-xs text-slate-500 mt-0.5 truncate">{rest.address}</p>
                <div className="mt-1.5">
                  <DataSourceBadge source={rest.data_source} />
                </div>
              </div>

              <button
                type="button"
                onClick={() => toggleRestaurantSponsor(rest)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold shrink-0 transition-colors ${
                  rest.is_sponsored
                    ? "bg-slate-200 text-slate-700 hover:bg-slate-300"
                    : "bg-amber-500 text-white hover:bg-amber-600"
                }`}
              >
                {rest.is_sponsored ? "Gỡ nhãn tài trợ" : "Gắn nhãn Tài trợ"}
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Sponsored Destinations */}
      <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs">
        <h2 className="text-base font-extrabold text-slate-900 flex items-center gap-2 mb-4">
          <ShieldCheck className="w-5 h-5 text-teal-600" />
          Danh sách Địa điểm Du lịch Hợp tác ({destinations.filter((d) => d.is_sponsored).length}{" "}
          đang tài trợ)
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {destinations.map((dest) => (
            <div
              key={dest.id}
              className={`p-4 rounded-xl border flex items-center justify-between gap-4 ${
                dest.is_sponsored
                  ? "bg-amber-50/40 border-amber-300"
                  : "bg-slate-50/60 border-slate-200"
              }`}
            >
              <div className="min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="text-sm font-bold text-slate-900">{dest.name}</span>
                  {dest.is_sponsored && <SponsoredBadge label={dest.sponsor_label} />}
                </div>
                <p className="text-xs text-slate-500 mt-0.5 truncate">{dest.address}</p>
              </div>

              <button
                type="button"
                onClick={() => toggleDestinationSponsor(dest)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold shrink-0 transition-colors ${
                  dest.is_sponsored
                    ? "bg-slate-200 text-slate-700 hover:bg-slate-300"
                    : "bg-teal-600 text-white hover:bg-teal-700"
                }`}
              >
                {dest.is_sponsored ? "Gỡ nhãn tài trợ" : "Gắn nhãn Tài trợ"}
              </button>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
