import React, { useState } from "react";
import { Edit3, Eye, EyeOff, Map, Plus, Search } from "lucide-react";
import {
  DataSourceBadge,
  ModalDialog,
  RbacNoticeBanner,
  StatusBadge,
} from "../../components/CommonUI";
import { useAuth } from "../../hooks/useAuth";
import { adminApi } from "../../services/api/client";

const REGIONS = ["Tất cả", "Bắc Bộ", "Trung Bộ", "Tây Nguyên", "Nam Bộ"];

export default function ProvincesPage({ provinces, onRefresh, showToast }) {
  const { user } = useAuth();
  const canEditProvinces = user?.role === "super_admin" || user?.role === "content_admin";

  const [selectedRegion, setSelectedRegion] = useState("Tất cả");
  const [searchQuery, setSearchQuery] = useState("");
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formData, setFormData] = useState({
    id: null,
    code: "",
    name: "",
    region: "Nam Bộ",
    description: "",
    hero_image: "",
    center_lat: 10.7769,
    center_lng: 106.7009,
    is_active: true,
    data_source: "internal",
  });

  const filteredProvinces = (provinces || []).filter((prov) => {
    const matchesRegion =
      selectedRegion === "Tất cả" || prov.region === selectedRegion;
    if (!matchesRegion) return false;
    if (!searchQuery.trim()) return true;
    const q = searchQuery.trim().toLowerCase();
    return (
      prov.name.toLowerCase().includes(q) ||
      prov.code.toLowerCase().includes(q) ||
      (prov.description && prov.description.toLowerCase().includes(q))
    );
  });

  const openAddModal = () => {
    setFormData({
      id: null,
      code: "",
      name: "",
      region: "Nam Bộ",
      description: "",
      hero_image:
        "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1200&q=80",
      center_lat: 10.7769,
      center_lng: 106.7009,
      is_active: true,
      data_source: "internal",
    });
    setIsModalOpen(true);
  };

  const openEditModal = (prov) => {
    setFormData({ ...prov });
    setIsModalOpen(true);
  };

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      await adminApi.saveProvince(
        {
          ...formData,
          center_lat: parseFloat(formData.center_lat),
          center_lng: parseFloat(formData.center_lng),
        },
        user
      );
      showToast(`Đã lưu thông tin tỉnh/thành: ${formData.name}`);
      setIsModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  const toggleActiveStatus = async (prov) => {
    if (!canEditProvinces) {
      showToast("Chỉ Super Admin hoặc Content Admin mới được bật/tắt tỉnh thành.", "error");
      return;
    }
    try {
      await adminApi.saveProvince({ ...prov, is_active: !prov.is_active }, user);
      showToast(
        `Đã ${!prov.is_active ? "kích hoạt hiển thị" : "tạm ẩn"} tỉnh/thành ${prov.name}`
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
            <Map className="w-6 h-6 text-teal-600" />
            Quản Lý Tỉnh / Thành Phố ({provinces?.length || 0} Tỉnh/Thành)
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Quản lý 10 tỉnh/thành phố du lịch trọng điểm thuộc 4 vùng miền Việt Nam, tọa độ tâm bản đồ và trạng thái hiển
            thị trên ứng dụng di động Flutter.
          </p>
        </div>

        {canEditProvinces && (
          <button
            type="button"
            onClick={openAddModal}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-teal-600 hover:bg-teal-700 text-white text-xs font-bold shadow-sm transition-colors"
          >
            <Plus className="w-4 h-4" />
            Thêm Tỉnh / Thành mới
          </button>
        )}
      </div>

      {/* Bộ lọc Vùng miền & Thanh tìm kiếm Tỉnh/Thành */}
      <div className="bg-white rounded-2xl border border-slate-200 p-4 mb-6 shadow-xs flex flex-col md:flex-row gap-4 items-stretch md:items-center justify-between">
        <div className="flex flex-wrap items-center gap-2">
          {REGIONS.map((reg) => {
            const count =
              reg === "Tất cả"
                ? provinces?.length || 0
                : provinces?.filter((p) => p.region === reg).length || 0;
            const isSelected = selectedRegion === reg;
            return (
              <button
                key={reg}
                type="button"
                onClick={() => setSelectedRegion(reg)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-colors flex items-center gap-1.5 ${
                  isSelected
                    ? "bg-teal-600 text-white shadow-xs"
                    : "bg-slate-100 hover:bg-slate-200 text-slate-700"
                }`}
              >
                <span>{reg}</span>
                <span
                  className={`px-1.5 py-0.5 rounded-md text-[10px] font-extrabold ${
                    isSelected ? "bg-teal-800 text-teal-100" : "bg-slate-200 text-slate-600"
                  }`}
                >
                  {count}
                </span>
              </button>
            );
          })}
        </div>

        <div className="relative min-w-[260px]">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Tìm theo tên tỉnh, mã tỉnh..."
            className="w-full pl-9 pr-3 py-2 text-xs border border-slate-300 rounded-xl focus:outline-none focus:border-teal-500 focus:ring-1 focus:ring-teal-500"
          />
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        {filteredProvinces.map((prov) => (
          <div
            key={prov.id}
            className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-xs hover:shadow-md transition-shadow flex flex-col"
          >
            <div className="h-40 bg-slate-200 relative">
              <img
                src={
                  prov.hero_image ||
                  "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80"
                }
                alt={prov.name}
                className="w-full h-full object-cover"
              />
              <div className="absolute top-3 left-3 flex items-center gap-2">
                <span className="px-2.5 py-1 rounded-lg bg-slate-900/80 backdrop-blur-xs text-white text-xs font-extrabold">
                  Mã: {prov.code}
                </span>
                <span className="px-2.5 py-1 rounded-lg bg-teal-600/90 text-white text-xs font-semibold">
                  {prov.region}
                </span>
              </div>
              <div className="absolute top-3 right-3">
                <StatusBadge status={prov.is_active ? "published" : "hidden"} />
              </div>
            </div>

            <div className="p-5 flex-1 flex flex-col justify-between">
              <div>
                <h3 className="text-lg font-extrabold text-slate-900">{prov.name}</h3>
                <p className="text-xs text-slate-600 mt-1.5 line-clamp-3 leading-relaxed">
                  {prov.description}
                </p>

                <div className="mt-4 pt-3 border-t border-slate-100 grid grid-cols-3 gap-2 text-center">
                  <div className="bg-slate-50 rounded-lg p-2">
                    <span className="block text-sm font-extrabold text-teal-700">
                      {prov.destination_count ?? 0}
                    </span>
                    <span className="text-[11px] text-slate-500">Địa điểm</span>
                  </div>
                  <div className="bg-slate-50 rounded-lg p-2">
                    <span className="block text-sm font-extrabold text-amber-600">
                      {prov.food_count ?? 0}
                    </span>
                    <span className="text-[11px] text-slate-500">Đặc sản</span>
                  </div>
                  <div className="bg-slate-50 rounded-lg p-2">
                    <span className="block text-sm font-extrabold text-indigo-600">
                      {prov.restaurant_count ?? 0}
                    </span>
                    <span className="text-[11px] text-slate-500">Nhà hàng</span>
                  </div>
                </div>

                <div className="mt-3 flex items-center justify-between text-[11px] text-slate-500">
                  <span>
                    Tâm GPS: {prov.center_lat?.toFixed(4)}, {prov.center_lng?.toFixed(4)}
                  </span>
                  <DataSourceBadge source={prov.data_source} />
                </div>
              </div>

              {canEditProvinces && (
                <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => toggleActiveStatus(prov)}
                    className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold bg-slate-100 text-slate-700 hover:bg-slate-200"
                  >
                    {prov.is_active ? (
                      <>
                        <EyeOff className="w-3.5 h-3.5" /> Tạm ẩn
                      </>
                    ) : (
                      <>
                        <Eye className="w-3.5 h-3.5" /> Hiển thị
                      </>
                    )}
                  </button>
                  <button
                    type="button"
                    onClick={() => openEditModal(prov)}
                    className="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-semibold bg-teal-50 text-teal-700 hover:bg-teal-100"
                  >
                    <Edit3 className="w-3.5 h-3.5" /> Chỉnh sửa
                  </button>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Modal Add / Edit Province */}
      <ModalDialog
        isOpen={isModalOpen}
        title={formData.id ? `Chỉnh sửa Tỉnh/Thành: ${formData.name}` : "Thêm Tỉnh/Thành Phố Mới"}
        subtitle="Cấu hình thông tin hành chính và tọa độ tâm bản đồ cho tỉnh/thành"
        onClose={() => setIsModalOpen(false)}
      >
        <form onSubmit={handleSave} className="space-y-4 text-sm">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Mã Tỉnh (Code)</label>
              <input
                type="text"
                required
                value={formData.code}
                onChange={(e) => setFormData({ ...formData, code: e.target.value.toUpperCase() })}
                placeholder="VD: HCM, DN, DL"
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
            <div className="sm:col-span-2">
              <label className="block text-xs font-bold text-slate-700 mb-1">
                Tên Tỉnh / Thành phố
              </label>
              <input
                type="text"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="VD: TP. Hồ Chí Minh"
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Vùng miền</label>
              <select
                value={formData.region}
                onChange={(e) => setFormData({ ...formData, region: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              >
                <option value="Bắc Bộ">Bắc Bộ</option>
                <option value="Trung Bộ">Trung Bộ</option>
                <option value="Tây Nguyên">Tây Nguyên</option>
                <option value="Nam Bộ">Nam Bộ</option>
                <option value="Đồng bằng sông Cửu Long">Đồng bằng sông Cửu Long</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">Vĩ độ tâm (Lat)</label>
              <input
                type="number"
                step="0.0001"
                required
                value={formData.center_lat}
                onChange={(e) => setFormData({ ...formData, center_lat: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1">
                Kinh độ tâm (Lng)
              </label>
              <input
                type="number"
                step="0.0001"
                required
                value={formData.center_lng}
                onChange={(e) => setFormData({ ...formData, center_lng: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Ảnh đại diện (URL)</label>
            <input
              type="url"
              value={formData.hero_image || ""}
              onChange={(e) => setFormData({ ...formData, hero_image: e.target.value })}
              className="w-full px-3 py-2 border border-slate-300 rounded-xl"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 mb-1">Mô tả tổng quan</label>
            <textarea
              rows={3}
              required
              value={formData.description || ""}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-3 py-2 border border-slate-300 rounded-xl"
            />
          </div>

          <div className="flex items-center justify-between pt-3 border-t border-slate-200">
            <label className="inline-flex items-center gap-2 text-xs font-semibold text-slate-700">
              <input
                type="checkbox"
                checked={formData.is_active}
                onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                className="rounded text-teal-600"
              />
              Kích hoạt hiển thị trên ứng dụng di động
            </label>

            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => setIsModalOpen(false)}
                className="px-4 py-2 rounded-xl bg-slate-100 text-slate-700 text-xs font-bold"
              >
                Hủy
              </button>
              <button
                type="submit"
                className="px-5 py-2 rounded-xl bg-teal-600 hover:bg-teal-700 text-white text-xs font-bold shadow-sm"
              >
                Lưu Tỉnh / Thành
              </button>
            </div>
          </div>
        </form>
      </ModalDialog>
    </div>
  );
}
