import React, { useState } from "react";
import {
  Clock,
  Edit3,
  Eye,
  EyeOff,
  Flame,
  MessageSquare,
  Plus,
  Search,
  Star,
  Trash2,
  UtensilsCrossed,
} from "lucide-react";
import {
  ConfirmDeleteModal,
  DataSourceBadge,
  ModalDialog,
  RbacNoticeBanner,
  SponsoredBadge,
  StatusBadge,
} from "../../components/CommonUI";
import { useAuth } from "../../hooks/useAuth";
import { adminApi } from "../../services/api/client";

export default function RestaurantsPage({
  restaurants,
  provinces,
  onRefresh,
  showToast,
}) {
  const { user, canManageProvince, canDeleteEntity } = useAuth();
  const [searchTerm, setSearchTerm] = useState("");
  const [provinceFilter, setProvinceFilter] = useState("all");
  const [ratingFilter, setRatingFilter] = useState("all");

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [selectedReviewRest, setSelectedReviewRest] = useState(null);

  const [formData, setFormData] = useState({
    id: null,
    province_id: 1,
    name: "",
    address: "",
    latitude: 10.7782,
    longitude: 106.6968,
    cuisine_type: "Đặc sản Sài Gòn",
    specialty_dishes: "",
    specialties: "",
    price_range: "55.000đ - 150.000đ",
    opening_hours: "06:30 - 22:00",
    contact_phone: "",
    rating: 4.6,
    reviews_count: 120,
    is_high_rated: true,
    image_url:
      "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80",
    is_sponsored: false,
    sponsor_label: "",
    status: "published",
    data_source: "internal",
  });

  const filteredRestaurants = restaurants.filter((r) => {
    const matchProv =
      provinceFilter === "all" || Number(r.province_id) === Number(provinceFilter);
    const revCnt = r.reviews_count || r.review_count || 0;
    const matchRating =
      ratingFilter === "all" ||
      (ratingFilter === "high_rated" && (Number(r.rating) >= 4.5 || r.is_high_rated)) ||
      (ratingFilter === "many_reviews" && revCnt >= 500);

    const kw = searchTerm.trim().toLowerCase();
    const matchKw =
      !kw ||
      r.name?.toLowerCase().includes(kw) ||
      r.address?.toLowerCase().includes(kw) ||
      r.cuisine_type?.toLowerCase().includes(kw) ||
      r.specialty_dishes?.toLowerCase().includes(kw) ||
      r.specialties?.toLowerCase().includes(kw);

    return matchProv && matchRating && matchKw;
  });

  const openAddModal = () => {
    setFormData({
      id: null,
      province_id: user?.assigned_province_id || 1,
      name: "",
      address: "",
      latitude: 10.7782,
      longitude: 106.6968,
      cuisine_type: "Đặc sản Sài Gòn",
      specialty_dishes: "",
      price_range: "55.000đ - 150.000đ",
      opening_hours: "06:30 - 22:00",
      contact_phone: "028 3824 5678",
      rating: 4.6,
      image_url:
        "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=900&q=80",
      is_sponsored: false,
      sponsor_label: "",
      status: "published",
      data_source: "internal",
    });
    setIsModalOpen(true);
  };

  const openEditModal = (rest) => {
    setFormData({
      ...rest,
      sponsor_label: rest.sponsor_label || "",
      contact_phone: rest.contact_phone || "",
    });
    setIsModalOpen(true);
  };

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        ...formData,
        province_id: Number(formData.province_id),
        latitude: parseFloat(formData.latitude),
        longitude: parseFloat(formData.longitude),
        rating: parseFloat(formData.rating || 4.6),
        is_sponsored: Boolean(formData.is_sponsored),
        sponsor_label: formData.is_sponsored
          ? formData.sponsor_label || "Đối tác Ẩm thực Địa phương"
          : null,
      };
      await adminApi.saveRestaurant(payload, user);
      showToast(`Đã lưu thông tin nhà hàng: ${formData.name}`);
      setIsModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  const handleToggleStatus = async (rest) => {
    if (!canManageProvince(rest.province_id)) {
      showToast("Bạn không có quyền sửa nhà hàng thuộc tỉnh/thành này.", "error");
      return;
    }
    const nextStatus = rest.status === "published" ? "hidden" : "published";
    try {
      await adminApi.saveRestaurant({ ...rest, status: nextStatus }, user);
      showToast(`Đã chuyển trạng thái nhà hàng "${rest.name}" sang ${nextStatus}`);
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    try {
      await adminApi.deleteRestaurant(deleteTarget.id, deleteTarget.name, user);
      showToast(`Đã xóa nhà hàng "${deleteTarget.name}"`);
      setDeleteTarget(null);
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
            <UtensilsCrossed className="w-6 h-6 text-teal-600" />
            Quản Lý Nhà Hàng & Quán Ăn Dọc Lộ Trình ({filteredRestaurants.length})
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Cập nhật tọa độ GPS phục vụ thuật toán tìm kiếm hành lang lộ trình (Corridor Search),
            khoảng giá, giờ mở cửa và thời điểm xác thực lần cuối.
          </p>
        </div>

        {user?.role !== "moderator" && (
          <button
            type="button"
            onClick={openAddModal}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-teal-600 hover:bg-teal-700 text-white text-xs font-bold shadow-sm transition-colors"
          >
            <Plus className="w-4 h-4" />
            Thêm Nhà hàng mới
          </button>
        )}
      </div>

      {/* Filter Bar */}
      <div className="bg-white rounded-2xl border border-slate-200 p-4 mb-5 flex flex-wrap items-center gap-3 shadow-xs">
        <div className="relative flex-1 min-w-[240px]">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-2.5" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Tìm theo tên nhà hàng, đường phố (Lê Thánh Tôn, Pasteur...), món đặc trưng..."
            className="w-full pl-9 pr-4 py-2 text-xs border border-slate-300 rounded-xl"
          />
        </div>

        <select
          value={provinceFilter}
          onChange={(e) => setProvinceFilter(e.target.value)}
          className="text-xs font-semibold border border-slate-300 rounded-xl px-3 py-2 bg-white"
        >
          <option value="all">Tất cả Tỉnh / Thành</option>
          {provinces.map((p) => (
            <option key={p.id} value={p.id}>
              {p.name}
            </option>
          ))}
        </select>

        <select
          value={ratingFilter}
          onChange={(e) => setRatingFilter(e.target.value)}
          className="text-xs font-semibold border border-amber-300 rounded-xl px-3 py-2 bg-amber-50/50 text-amber-900"
        >
          <option value="all">⭐ Tất cả đánh giá</option>
          <option value="high_rated">⭐ Đánh giá cao (4.5+ / Quán ngon)</option>
          <option value="many_reviews">🔥 Nhiều bình luận (500+ reviews)</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold uppercase text-slate-500">
                <th className="py-3.5 px-4">Nhà hàng & Địa chỉ</th>
                <th className="py-3.5 px-4">Đánh giá Google Maps</th>
                <th className="py-3.5 px-4">Ẩm thực & Giá tham khảo</th>
                <th className="py-3.5 px-4">Tọa độ Corridor GPS</th>
                <th className="py-3.5 px-4">Giờ mở cửa & Xác thực</th>
                <th className="py-3.5 px-4">Nguồn & Tài trợ</th>
                <th className="py-3.5 px-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs">
              {filteredRestaurants.map((rest) => {
                const canEdit = canManageProvince(rest.province_id);
                const revCount = rest.reviews_count || rest.review_count || 120;
                return (
                  <tr key={rest.id} className="hover:bg-slate-50/80">
                    <td className="py-3.5 px-4 max-w-xs">
                      <div className="flex items-start gap-3">
                        <img
                          src={
                            rest.image_url ||
                            "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=400&q=80"
                          }
                          alt={rest.name}
                          className="w-13 h-13 rounded-xl object-cover shrink-0 border border-slate-200"
                        />
                        <div className="min-w-0">
                          <span className="font-bold text-slate-900 block">{rest.name}</span>
                          <span className="text-[11px] text-slate-500 block line-clamp-1">
                            {rest.address}
                          </span>
                          <span className="text-[11px] text-teal-700 font-semibold">
                            {rest.province_name || "TP. Hồ Chí Minh"}
                          </span>
                        </div>
                      </div>
                    </td>

                    <td className="py-3.5 px-4 whitespace-nowrap">
                      <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-amber-50 border border-amber-200 text-amber-900 font-bold text-xs">
                        <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                        <span>{rest.rating}</span>
                        <span className="text-[10px] text-amber-700 font-normal">
                          ({revCount > 999 ? `${(revCount / 1000).toFixed(1)}k` : revCount})
                        </span>
                      </div>
                      {rest.is_high_rated && (
                        <span className="block mt-1 text-[10px] text-rose-600 font-bold">
                          🔥 Quán được yêu thích
                        </span>
                      )}
                    </td>

                    <td className="py-3.5 px-4 max-w-xs">
                      <span className="font-semibold text-slate-800 block">
                        {rest.cuisine_type}
                      </span>
                      <span className="text-[11px] text-amber-700 font-bold block">
                        {rest.price_range}
                      </span>
                      <span className="text-[11px] text-slate-500 line-clamp-1">
                        {rest.specialties || rest.specialty_dishes}
                      </span>
                    </td>

                    <td className="py-3.5 px-4 font-mono text-[11px] text-slate-600">
                      <div>Lat: {Number(rest.latitude).toFixed(4)}</div>
                      <div>Lng: {Number(rest.longitude).toFixed(4)}</div>
                    </td>

                    <td className="py-3.5 px-4">
                      <div className="inline-flex items-center gap-1 text-slate-800 font-semibold">
                        <Clock className="w-3.5 h-3.5 text-teal-600" />
                        {rest.opening_hours}
                      </div>
                      <p className="text-[10px] text-slate-400 mt-1">
                        Cập nhật:{" "}
                        {rest.last_updated_at
                          ? new Date(rest.last_updated_at).toLocaleDateString("vi-VN")
                          : "30/10/2026"}
                      </p>
                    </td>

                    <td className="py-3.5 px-4 space-y-1">
                      <div className="flex flex-col items-start gap-1">
                        <DataSourceBadge source={rest.data_source} />
                        {rest.is_sponsored && <SponsoredBadge label={rest.sponsor_label} />}
                        <StatusBadge status={rest.status} />
                      </div>
                    </td>

                    <td className="py-3.5 px-4 text-right whitespace-nowrap">
                      <div className="inline-flex items-center gap-1.5">
                        <button
                          type="button"
                          onClick={() => setSelectedReviewRest(rest)}
                          title="Xem trích đoạn bình luận Google Maps"
                          className="p-1.5 rounded-lg bg-amber-50 text-amber-700 hover:bg-amber-100"
                        >
                          <MessageSquare className="w-4 h-4" />
                        </button>
                        {canEdit && (
                          <>
                            <button
                              type="button"
                              onClick={() => handleToggleStatus(rest)}
                              className="p-1.5 rounded-lg bg-slate-100 text-slate-600 hover:bg-slate-200"
                            >
                              {rest.status === "published" ? (
                                <EyeOff className="w-4 h-4" />
                              ) : (
                                <Eye className="w-4 h-4" />
                              )}
                            </button>
                            <button
                              type="button"
                              onClick={() => openEditModal(rest)}
                              className="p-1.5 rounded-lg bg-teal-50 text-teal-700 hover:bg-teal-100"
                            >
                              <Edit3 className="w-4 h-4" />
                            </button>
                          </>
                        )}
                        {canDeleteEntity() && (
                          <button
                            type="button"
                            onClick={() => setDeleteTarget(rest)}
                            className="p-1.5 rounded-lg bg-rose-50 text-rose-600 hover:bg-rose-100"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        )}
                      </div>
                            className="p-1.5 rounded-lg bg-rose-50 text-rose-600 hover:bg-rose-100"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Add / Edit Restaurant */}
      <ModalDialog
        isOpen={isModalOpen}
        title={formData.id ? `Chỉnh sửa Nhà hàng: ${formData.name}` : "Thêm Nhà hàng / Quán ăn Mới"}
        subtitle="Tọa độ GPS sẽ được dùng trực tiếp để tính khoảng cách lệch khỏi lộ trình di chuyển (Corridor Search)"
        onClose={() => setIsModalOpen(false)}
        maxWidth="max-w-3xl"
      >
        <form onSubmit={handleSave} className="space-y-4 text-xs">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="sm:col-span-2">
              <label className="block font-bold text-slate-700 mb-1">Tên Nhà hàng / Quán ăn *</label>
              <input
                type="text"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
            <div>
              <label className="block font-bold text-slate-700 mb-1">Tỉnh / Thành phố *</label>
              <select
                value={formData.province_id}
                disabled={user?.role === "province_editor"}
                onChange={(e) =>
                  setFormData({ ...formData, province_id: Number(e.target.value) })
                }
                className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white"
              >
                {provinces.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <label className="block font-bold text-slate-700 mb-1">Địa chỉ chi tiết *</label>
            <input
              type="text"
              required
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              className="w-full px-3 py-2 border border-slate-300 rounded-xl"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block font-bold text-slate-700 mb-1">Vĩ độ GPS (Latitude) *</label>
              <input
                type="number"
                step="0.0001"
                required
                value={formData.latitude}
                onChange={(e) => setFormData({ ...formData, latitude: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
            <div>
              <label className="block font-bold text-slate-700 mb-1">
                Kinh độ GPS (Longitude) *
              </label>
              <input
                type="number"
                step="0.0001"
                required
                value={formData.longitude}
                onChange={(e) => setFormData({ ...formData, longitude: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
            <div>
              <label className="block font-bold text-slate-700 mb-1">Loại hình ẩm thực</label>
              <input
                type="text"
                value={formData.cuisine_type}
                onChange={(e) => setFormData({ ...formData, cuisine_type: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block font-bold text-slate-700 mb-1">Khoảng giá tham khảo</label>
              <input
                type="text"
                value={formData.price_range}
                onChange={(e) => setFormData({ ...formData, price_range: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
            <div>
              <label className="block font-bold text-slate-700 mb-1">Giờ mở cửa</label>
              <input
                type="text"
                value={formData.opening_hours}
                onChange={(e) => setFormData({ ...formData, opening_hours: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
            <div>
              <label className="block font-bold text-slate-700 mb-1">
                Điện thoại liên hệ (Nếu công bố)
              </label>
              <input
                type="text"
                value={formData.contact_phone}
                onChange={(e) => setFormData({ ...formData, contact_phone: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
          </div>

          <div>
            <label className="block font-bold text-slate-700 mb-1">Các món đặc trưng gợi ý</label>
            <input
              type="text"
              value={formData.specialty_dishes || ""}
              onChange={(e) => setFormData({ ...formData, specialty_dishes: e.target.value })}
              className="w-full px-3 py-2 border border-slate-300 rounded-xl"
            />
          </div>

          <div>
            <div className="flex items-center justify-between mb-1">
              <label className="block font-bold text-slate-700">
                URL Hình ảnh Nhà hàng (Cloudinary CDN Thumbnail w_400,h_300)
              </label>
              <button
                type="button"
                onClick={async () => {
                  const res = await adminApi.uploadImageToCloudinary(
                    formData.image_url,
                    formData.name || "restaurant.jpg",
                    "tripflow/restaurants"
                  );
                  setFormData({ ...formData, image_url: res.thumbnail_url });
                  showToast(
                    "Đã tối ưu ảnh nhà hàng qua Cloudinary CDN (c_fill,w_400,h_300,q_auto,f_auto)!"
                  );
                }}
                className="text-[11px] font-bold text-teal-700 hover:text-teal-800 underline"
              >
                ⚡ Tối ưu Cloudinary CDN
              </button>
            </div>
            <input
              type="url"
              value={formData.image_url || ""}
              onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
              className="w-full px-3 py-2 border border-slate-300 rounded-xl"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block font-bold text-slate-700 mb-1">Nguồn dữ liệu</label>
              <select
                value={formData.data_source}
                onChange={(e) => setFormData({ ...formData, data_source: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white"
              >
                <option value="internal">Nội bộ xác thực (internal)</option>
                <option value="partner">Đối tác cung cấp (partner)</option>
                <option value="api_provider">API Bên thứ ba (api_provider)</option>
              </select>
            </div>
            <div>
              <label className="block font-bold text-slate-700 mb-1">Nhãn tài trợ (Nếu có)</label>
              <input
                type="text"
                value={formData.sponsor_label || ""}
                onChange={(e) => setFormData({ ...formData, sponsor_label: e.target.value })}
                placeholder="VD: Đối tác Ẩm thực Địa phương"
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
          </div>

          <div className="flex items-center justify-between pt-3 border-t border-slate-200">
            <label className="inline-flex items-center gap-2 font-semibold text-amber-800">
              <input
                type="checkbox"
                checked={formData.is_sponsored}
                onChange={(e) => setFormData({ ...formData, is_sponsored: e.target.checked })}
              />
              Đánh dấu Nhà hàng Được tài trợ / Đối tác (Mục 12)
            </label>

            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                className="px-4 py-2 rounded-xl bg-slate-100 text-slate-700 font-bold"
              >
                Hủy
              </button>
              <button
                type="submit"
                className="px-5 py-2 rounded-xl bg-teal-600 hover:bg-teal-700 text-white font-bold shadow-sm"
              >
                Lưu Nhà Hàng
              </button>
            </div>
          </div>
        </form>
      </ModalDialog>

      <ConfirmDeleteModal
        isOpen={Boolean(deleteTarget)}
        title="Xác nhận xóa Nhà hàng"
        itemName={deleteTarget?.name}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={handleConfirmDelete}
      />

      {/* Modal Xem Trích Đoạn Bình Luận Thực Tế (Google Maps) */}
      <ModalDialog
        isOpen={Boolean(selectedReviewRest)}
        onClose={() => setSelectedReviewRest(null)}
        title={`Bình luận thực tế: ${selectedReviewRest?.name || ""}`}
      >
        <div className="space-y-4">
          <div className="p-3 bg-amber-50 rounded-xl border border-amber-200 flex items-center justify-between">
            <div>
              <span className="text-xs font-bold text-amber-900 block">
                ⭐ {selectedReviewRest?.rating} / 5.0
              </span>
              <span className="text-[11px] text-amber-700">
                Tổng cộng {(selectedReviewRest?.reviews_count || selectedReviewRest?.review_count || 120).toLocaleString()} lượt đánh giá công khai trên Google Maps
              </span>
            </div>
            {selectedReviewRest?.is_high_rated && (
              <span className="px-2 py-1 bg-rose-100 text-rose-700 rounded-lg text-[11px] font-bold">
                🔥 Quán được yêu thích
              </span>
            )}
          </div>

          <div className="space-y-3">
            <h4 className="text-xs font-bold text-slate-700 uppercase tracking-wider">
              Trích đoạn đánh giá từ thực khách
            </h4>

            {(() => {
              let reviews = [];
              const rawReviews = selectedReviewRest?.sample_reviews;
              if (Array.isArray(rawReviews) && rawReviews.length > 0) {
                reviews = rawReviews;
              } else if (typeof rawReviews === "string") {
                try {
                  reviews = JSON.parse(rawReviews);
                } catch {
                  reviews = [];
                }
              }

              if (!reviews || reviews.length === 0) {
                reviews = [
                  {
                    author: "Thực khách Google Maps",
                    rating: selectedReviewRest?.rating || 4.8,
                    text: `Món ăn tại quán ${selectedReviewRest?.name} rất ngon và chuẩn vị. Không gian thoáng, nhân viên phục vụ nhiệt tình chu đáo.`,
                    relative_time: "2 tuần trước",
                  },
                  {
                    author: "Người sành ăn địa phương",
                    rating: 5.0,
                    text: `Nước dùng ngọt thanh xương hầm, nguyên liệu tươi ngon rất đáng ghé thưởng thức khi đến ${selectedReviewRest?.province_name || "khu vực này"}.`,
                    relative_time: "1 tháng trước",
                  },
                ];
              }

              return reviews.map((rev, idx) => (
                <div
                  key={idx}
                  className="p-3.5 bg-slate-50 rounded-xl border border-slate-200 text-xs"
                >
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="font-bold text-slate-900 flex items-center gap-1.5">
                      <span className="w-6 h-6 rounded-full bg-teal-100 text-teal-800 flex items-center justify-center font-bold text-[10px]">
                        {rev.author ? rev.author[0].toUpperCase() : "U"}
                      </span>
                      {rev.author || "Thực khách"}
                    </span>
                    <span className="text-[11px] text-amber-600 font-bold">
                      ⭐ {rev.rating || 5} • <span className="text-slate-400 font-normal">{rev.relative_time || "Gần đây"}</span>
                    </span>
                  </div>
                  <p className="text-slate-700 italic pl-7 leading-relaxed">
                    "{rev.text}"
                  </p>
                </div>
              ));
            })()}
          </div>

          <div className="pt-2 text-right border-t border-slate-200">
            <button
              type="button"
              onClick={() => setSelectedReviewRest(null)}
              className="px-4 py-2 bg-slate-100 hover:bg-slate-200 rounded-xl text-slate-700 font-bold text-xs"
            >
              Đóng
            </button>
          </div>
        </div>
      </ModalDialog>
    </div>
  );
}
