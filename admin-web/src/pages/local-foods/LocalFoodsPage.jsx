import React, { useState } from "react";
import { Edit3, Plus, Search, Soup, Trash2 } from "lucide-react";
import {
  ConfirmDeleteModal,
  DataSourceBadge,
  ModalDialog,
  RbacNoticeBanner,
  StatusBadge,
} from "../../components/CommonUI";
import { useAuth } from "../../hooks/useAuth";
import { adminApi } from "../../services/api/client";

export default function LocalFoodsPage({
  localFoods,
  provinces,
  restaurants,
  onRefresh,
  showToast,
}) {
  const { user, canManageProvince, canDeleteEntity } = useAuth();
  const [searchTerm, setSearchTerm] = useState("");
  const [provinceFilter, setProvinceFilter] = useState("all");

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);

  const [formData, setFormData] = useState({
    id: null,
    province_id: 1,
    name: "",
    description: "",
    story_origin: "",
    image_url:
      "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=80",
    best_season_or_time: "Quanh năm (Ngon nhất vào buổi sáng hoặc tối)",
    avg_price_range: "45.000đ - 110.000đ",
    recommended_restaurant_ids: [1, 4],
    status: "published",
    data_source: "internal",
    license_info: "Ban Biên Tập Ẩm thực TripFlow",
  });

  const filteredFoods = localFoods.filter((f) => {
    const matchProv =
      provinceFilter === "all" || Number(f.province_id) === Number(provinceFilter);
    const kw = searchTerm.trim().toLowerCase();
    const matchKw =
      !kw ||
      f.name?.toLowerCase().includes(kw) ||
      f.description?.toLowerCase().includes(kw) ||
      f.story_origin?.toLowerCase().includes(kw);
    return matchProv && matchKw;
  });

  const openAddModal = () => {
    setFormData({
      id: null,
      province_id: user?.assigned_province_id || 1,
      name: "",
      description: "",
      story_origin: "",
      image_url:
        "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=80",
      best_season_or_time: "Quanh năm",
      avg_price_range: "45.000đ - 95.000đ",
      recommended_restaurant_ids: [1, 4],
      status: "published",
      data_source: "internal",
      license_info: "Ban Biên Tập Ẩm thực TripFlow",
    });
    setIsModalOpen(true);
  };

  const openEditModal = (food) => {
    setFormData({
      ...food,
      recommended_restaurant_ids: food.recommended_restaurant_ids || [],
    });
    setIsModalOpen(true);
  };

  const toggleRestaurantRecommendation = (restId) => {
    const current = formData.recommended_restaurant_ids || [];
    if (current.includes(restId)) {
      setFormData({
        ...formData,
        recommended_restaurant_ids: current.filter((id) => id !== restId),
      });
    } else {
      setFormData({
        ...formData,
        recommended_restaurant_ids: [...current, restId],
      });
    }
  };

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      await adminApi.saveLocalFood(
        {
          ...formData,
          province_id: Number(formData.province_id),
        },
        user
      );
      showToast(`Đã lưu đặc sản/món ăn: ${formData.name}`);
      setIsModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    try {
      await adminApi.deleteLocalFood(deleteTarget.id, deleteTarget.name, user);
      showToast(`Đã xóa món ăn "${deleteTarget.name}"`);
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
            <Soup className="w-6 h-6 text-amber-600" />
            Quản Lý Đặc Sản & Món Ăn Địa Phương ({filteredFoods.length})
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Quản lý tên món, câu chuyện nguồn gốc, mùa thưởng thức, nguồn dữ liệu và liên kết nhà
            hàng gợi ý.
          </p>
        </div>

        {user?.role !== "moderator" && (
          <button
            type="button"
            onClick={openAddModal}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-amber-600 hover:bg-amber-700 text-white text-xs font-bold shadow-sm transition-colors"
          >
            <Plus className="w-4 h-4" />
            Thêm Đặc sản / Món ăn
          </button>
        )}
      </div>

      {/* Filters */}
      <div className="bg-white rounded-2xl border border-slate-200 p-4 mb-5 flex flex-wrap items-center gap-3 shadow-xs">
        <div className="relative flex-1 min-w-[240px]">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-2.5" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Tìm món ăn đặc sản (VD: Cơm tấm, Bánh mì, Hủ tiếu, Bánh xèo...)"
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
      </div>

      {/* Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {filteredFoods.map((food) => {
          const canEdit = canManageProvince(food.province_id);
          const linkedRestaurants = restaurants.filter((r) =>
            (food.recommended_restaurant_ids || []).includes(r.id)
          );

          return (
            <div
              key={food.id}
              className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-xs hover:shadow-md transition-shadow flex flex-col"
            >
              <div className="h-44 bg-slate-200 relative">
                <img
                  src={
                    food.image_url ||
                    "https://images.unsplash.com/photo-1512058564366-18510be2db19?auto=format&fit=crop&w=900&q=80"
                  }
                  alt={food.name}
                  className="w-full h-full object-cover"
                />
                <div className="absolute top-3 left-3">
                  <span className="px-2.5 py-1 rounded-lg bg-slate-900/80 text-white text-xs font-bold">
                    {food.province_name || "TP. Hồ Chí Minh"}
                  </span>
                </div>
                <div className="absolute top-3 right-3">
                  <StatusBadge status={food.status} />
                </div>
              </div>

              <div className="p-5 flex-1 flex flex-col justify-between">
                <div>
                  <h3 className="text-base font-extrabold text-slate-900">{food.name}</h3>
                  <p className="text-xs font-semibold text-amber-700 mt-1">
                    Giá tham khảo: {food.avg_price_range}
                  </p>
                  <p className="text-xs text-slate-600 mt-2 line-clamp-3 leading-relaxed">
                    {food.description}
                  </p>

                  {food.story_origin && (
                    <div className="mt-3 p-2.5 rounded-xl bg-amber-50/70 border border-amber-200/70 text-[11px] text-amber-900">
                      <strong>Câu chuyện món ăn:</strong> {food.story_origin}
                    </div>
                  )}

                  <div className="mt-3">
                    <span className="text-[11px] font-bold text-slate-700 block mb-1">
                      Nhà hàng gợi ý thưởng thức ({linkedRestaurants.length}):
                    </span>
                    <div className="flex flex-wrap gap-1">
                      {linkedRestaurants.map((r) => (
                        <span
                          key={r.id}
                          className="px-2 py-0.5 rounded-md bg-slate-100 text-slate-700 text-[11px] font-medium"
                        >
                          {r.name}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>

                <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between">
                  <DataSourceBadge source={food.data_source} />

                  <div className="flex items-center gap-1.5">
                    {canEdit && (
                      <button
                        type="button"
                        onClick={() => openEditModal(food)}
                        className="p-1.5 rounded-lg bg-teal-50 text-teal-700 hover:bg-teal-100"
                      >
                        <Edit3 className="w-4 h-4" />
                      </button>
                    )}
                    {canDeleteEntity() && (
                      <button
                        type="button"
                        onClick={() => setDeleteTarget(food)}
                        className="p-1.5 rounded-lg bg-rose-50 text-rose-600 hover:bg-rose-100"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    )}
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Modal Add / Edit Local Food */}
      <ModalDialog
        isOpen={isModalOpen}
        title={formData.id ? `Chỉnh sửa Món ăn: ${formData.name}` : "Thêm Đặc sản / Món ăn Mới"}
        subtitle="Giới thiệu đặc sản địa phương và gắn kết các nhà hàng chuẩn vị"
        onClose={() => setIsModalOpen(false)}
      >
        <form onSubmit={handleSave} className="space-y-4 text-xs">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="sm:col-span-2">
              <label className="block font-bold text-slate-700 mb-1">Tên món ăn / đặc sản *</label>
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

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block font-bold text-slate-700 mb-1">Khoảng giá tham khảo</label>
              <input
                type="text"
                value={formData.avg_price_range}
                onChange={(e) => setFormData({ ...formData, avg_price_range: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
            <div>
              <label className="block font-bold text-slate-700 mb-1">
                Thời điểm thưởng thức ngon nhất
              </label>
              <input
                type="text"
                value={formData.best_season_or_time}
                onChange={(e) => setFormData({ ...formData, best_season_or_time: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
          </div>

          <div>
            <label className="block font-bold text-slate-700 mb-1">Mô tả hương vị *</label>
            <textarea
              rows={2}
              required
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-3 py-2 border border-slate-300 rounded-xl"
            />
          </div>

          <div>
            <label className="block font-bold text-slate-700 mb-1">
              Câu chuyện nguồn gốc văn hóa ẩm thực
            </label>
            <textarea
              rows={2}
              value={formData.story_origin || ""}
              onChange={(e) => setFormData({ ...formData, story_origin: e.target.value })}
              className="w-full px-3 py-2 border border-slate-300 rounded-xl"
            />
          </div>

          <div>
            <label className="block font-bold text-slate-700 mb-1">
              Chọn các Nhà hàng gợi ý thưởng thức món này
            </label>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 max-h-36 overflow-y-auto p-3 rounded-xl border border-slate-200 bg-slate-50">
              {restaurants
                .filter((r) => Number(r.province_id) === Number(formData.province_id))
                .map((r) => (
                  <label key={r.id} className="inline-flex items-center gap-2 text-xs">
                    <input
                      type="checkbox"
                      checked={(formData.recommended_restaurant_ids || []).includes(r.id)}
                      onChange={() => toggleRestaurantRecommendation(r.id)}
                    />
                    <span className="truncate">{r.name}</span>
                  </label>
                ))}
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-3 border-t border-slate-200">
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              className="px-4 py-2 rounded-xl bg-slate-100 text-slate-700 font-bold"
            >
              Hủy
            </button>
            <button
              type="submit"
              className="px-5 py-2 rounded-xl bg-amber-600 hover:bg-amber-700 text-white font-bold shadow-sm"
            >
              Lưu Đặc Sản
            </button>
          </div>
        </form>
      </ModalDialog>

      <ConfirmDeleteModal
        isOpen={Boolean(deleteTarget)}
        title="Xác nhận xóa Đặc sản / Món ăn"
        itemName={deleteTarget?.name}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={handleConfirmDelete}
      />
    </div>
  );
}
