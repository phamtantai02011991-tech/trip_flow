import React, { useState } from "react";
import {
  Edit3,
  Eye,
  EyeOff,
  MapPin,
  Plus,
  Search,
  Star,
  Trash2,
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

export default function DestinationsPage({
  destinations,
  provinces,
  categories,
  onRefresh,
  showToast,
}) {
  const { user, canManageProvince, canDeleteEntity } = useAuth();

  const [searchTerm, setSearchTerm] = useState("");
  const [provinceFilter, setProvinceFilter] = useState("all");
  const [sourceFilter, setSourceFilter] = useState("all");

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);

  const [formData, setFormData] = useState({
    id: null,
    province_id: 1,
    category_id: 1,
    name: "",
    description: "",
    address: "",
    latitude: 10.777,
    longitude: 106.6953,
    opening_hours: "07:30 - 17:30",
    ticket_price_info: "Miễn phí",
    rating: 4.8,
    recommended_duration_mins: 90,
    is_featured: false,
    is_sponsored: false,
    sponsor_label: "",
    status: "published",
    data_source: "internal",
    source_attribution: "Ban Biên Tập TripFlow & Sở Du lịch TP.HCM",
    image_url:
      "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80",
    license_type: "owned",
    credit_author: "TripFlow Editorial Photography",
  });

  const filteredDestinations = destinations.filter((d) => {
    const matchProv =
      provinceFilter === "all" || Number(d.province_id) === Number(provinceFilter);
    const matchSource = sourceFilter === "all" || d.data_source === sourceFilter;
    const kw = searchTerm.trim().toLowerCase();
    const matchKw =
      !kw ||
      d.name?.toLowerCase().includes(kw) ||
      d.address?.toLowerCase().includes(kw) ||
      d.description?.toLowerCase().includes(kw);
    return matchProv && matchSource && matchKw;
  });

  const openAddModal = () => {
    const defaultProvId = user?.assigned_province_id || 1;
    setFormData({
      id: null,
      province_id: defaultProvId,
      category_id: 1,
      name: "",
      description: "",
      address: "",
      latitude: 10.777,
      longitude: 106.6953,
      opening_hours: "07:30 - 17:30",
      ticket_price_info: "Miễn phí",
      rating: 4.8,
      recommended_duration_mins: 90,
      is_featured: true,
      is_sponsored: false,
      sponsor_label: "",
      status: "published",
      data_source: "internal",
      source_attribution: "Ban Biên Tập TripFlow & Sở Du lịch TP.HCM",
      image_url:
        "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80",
      license_type: "owned",
      credit_author: "TripFlow Editorial Photography",
    });
    setIsModalOpen(true);
  };

  const openEditModal = (dest) => {
    const firstImg = dest.images?.[0] || {};
    setFormData({
      ...dest,
      sponsor_label: dest.sponsor_label || "",
      image_url:
        firstImg.image_url ||
        "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80",
      license_type: firstImg.license_type || "owned",
      credit_author: firstImg.credit_author || "TripFlow Studio",
    });
    setIsModalOpen(true);
  };

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        id: formData.id,
        province_id: Number(formData.province_id),
        category_id: Number(formData.category_id),
        name: formData.name,
        description: formData.description,
        address: formData.address,
        latitude: parseFloat(formData.latitude),
        longitude: parseFloat(formData.longitude),
        opening_hours: formData.opening_hours,
        ticket_price_info: formData.ticket_price_info,
        rating: parseFloat(formData.rating || 4.7),
        recommended_duration_mins: parseInt(formData.recommended_duration_mins || 90, 10),
        is_featured: Boolean(formData.is_featured),
        is_sponsored: Boolean(formData.is_sponsored),
        sponsor_label: formData.is_sponsored ? formData.sponsor_label || "Được tài trợ" : null,
        status: formData.status,
        data_source: formData.data_source,
        source_attribution: formData.source_attribution,
        images: [
          {
            image_url: formData.image_url,
            caption: formData.name,
            sort_order: 1,
            license_type: formData.license_type,
            credit_author: formData.credit_author,
          },
        ],
      };
      await adminApi.saveDestination(payload, user);
      showToast(
        `${formData.id ? "Đã cập nhật" : "Đã thêm mới"} địa điểm: ${formData.name}`
      );
      setIsModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  const handleToggleStatus = async (dest) => {
    if (!canManageProvince(dest.province_id)) {
      showToast("Bạn không có quyền chỉnh sửa địa điểm thuộc tỉnh/thành này.", "error");
      return;
    }
    const nextStatus = dest.status === "published" ? "hidden" : "published";
    try {
      await adminApi.saveDestination({ ...dest, status: nextStatus }, user);
      showToast(
        `Đã chuyển trạng thái "${dest.name}" sang ${
          nextStatus === "published" ? "Đang hiển thị" : "Đã ẩn"
        }`
      );
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    try {
      await adminApi.deleteDestination(deleteTarget.id, deleteTarget.name, user);
      showToast(`Đã xóa địa điểm "${deleteTarget.name}" và ghi nhận Audit Log.`);
      setDeleteTarget(null);
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  return (
    <div>
      <RbacNoticeBanner role={user?.role} assignedProvinceId={user?.assigned_province_id} />

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-xl font-extrabold text-slate-900 flex items-center gap-2">
            <MapPin className="w-6 h-6 text-teal-600" />
            Quản Lý Địa Điểm Du Lịch ({filteredDestinations.length})
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Thêm/sửa mô tả, hình ảnh, tọa độ GPS, danh mục, nguồn dữ liệu, bản quyền ảnh và duyệt
            hiển thị.
          </p>
        </div>

        {user?.role !== "moderator" && (
          <button
            type="button"
            onClick={openAddModal}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-teal-600 hover:bg-teal-700 text-white text-xs font-bold shadow-sm transition-colors"
          >
            <Plus className="w-4 h-4" />
            Thêm Địa điểm Du lịch
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
            placeholder="Tìm theo tên địa điểm, địa chỉ, mô tả..."
            className="w-full pl-9 pr-4 py-2 text-xs border border-slate-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-500"
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
              {p.name} ({p.code})
            </option>
          ))}
        </select>

        <select
          value={sourceFilter}
          onChange={(e) => setSourceFilter(e.target.value)}
          className="text-xs font-semibold border border-slate-300 rounded-xl px-3 py-2 bg-white"
        >
          <option value="all">Mọi nguồn dữ liệu</option>
          <option value="internal">Nội bộ xác thực (internal)</option>
          <option value="partner">Đối tác cung cấp (partner)</option>
          <option value="api_provider">API Bên thứ ba (api_provider)</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold uppercase text-slate-500">
                <th className="py-3.5 px-4">Địa điểm & Tỉnh/Thành</th>
                <th className="py-3.5 px-4">Danh mục & Vé</th>
                <th className="py-3.5 px-4">Tọa độ GPS</th>
                <th className="py-3.5 px-4">Nguồn dữ liệu & Bản quyền</th>
                <th className="py-3.5 px-4">Trạng thái</th>
                <th className="py-3.5 px-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs">
              {filteredDestinations.map((dest) => {
                const imgUrl =
                  dest.images?.[0]?.image_url ||
                  "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=400&q=80";
                const canEdit = canManageProvince(dest.province_id);

                return (
                  <tr key={dest.id} className="hover:bg-slate-50/80">
                    <td className="py-3.5 px-4 max-w-xs">
                      <div className="flex items-start gap-3">
                        <img
                          src={imgUrl}
                          alt={dest.name}
                          className="w-14 h-14 rounded-xl object-cover shrink-0 border border-slate-200"
                        />
                        <div className="min-w-0">
                          <div className="flex items-center gap-1.5 flex-wrap">
                            <span className="font-bold text-slate-900">{dest.name}</span>
                            {dest.is_featured && (
                              <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded bg-amber-100 text-amber-800 text-[10px] font-bold">
                                <Star className="w-3 h-3 fill-amber-500 text-amber-500" /> Nổi bật
                              </span>
                            )}
                          </div>
                          <p className="text-[11px] text-slate-500 mt-0.5 line-clamp-1">
                            {dest.address}
                          </p>
                          <div className="mt-1 flex items-center gap-2">
                            <span className="text-[11px] font-semibold text-teal-700">
                              {dest.province_name || `Province #${dest.province_id}`}
                            </span>
                            {dest.is_sponsored && <SponsoredBadge label={dest.sponsor_label} />}
                          </div>
                        </div>
                      </div>
                    </td>

                    <td className="py-3.5 px-4">
                      <span className="font-semibold text-slate-800 block">
                        {dest.category_name || "Di tích & Danh thắng"}
                      </span>
                      <span className="text-[11px] text-slate-500 block mt-0.5">
                        Vé: {dest.ticket_price_info}
                      </span>
                      <span className="text-[11px] text-slate-400 block">
                        Giờ: {dest.opening_hours}
                      </span>
                    </td>

                    <td className="py-3.5 px-4 font-mono text-[11px] text-slate-600">
                      <div>Lat: {Number(dest.latitude).toFixed(4)}</div>
                      <div>Lng: {Number(dest.longitude).toFixed(4)}</div>
                    </td>

                    <td className="py-3.5 px-4">
                      <DataSourceBadge source={dest.data_source} />
                      <p className="text-[11px] text-slate-500 mt-1 line-clamp-1">
                        {dest.source_attribution}
                      </p>
                      <p className="text-[10px] text-slate-400">
                        Ảnh: {dest.images?.[0]?.license_type || "owned"} (
                        {dest.images?.[0]?.credit_author || "TripFlow"})
                      </p>
                    </td>

                    <td className="py-3.5 px-4">
                      <StatusBadge status={dest.status} />
                    </td>

                    <td className="py-3.5 px-4 text-right whitespace-nowrap">
                      <div className="inline-flex items-center gap-1.5">
                        {canEdit && (
                          <>
                            <button
                              type="button"
                              onClick={() => handleToggleStatus(dest)}
                              title="Ẩn / Hiện địa điểm"
                              className="p-1.5 rounded-lg bg-slate-100 text-slate-600 hover:bg-slate-200"
                            >
                              {dest.status === "published" ? (
                                <EyeOff className="w-4 h-4" />
                              ) : (
                                <Eye className="w-4 h-4" />
                              )}
                            </button>
                            <button
                              type="button"
                              onClick={() => openEditModal(dest)}
                              title="Chỉnh sửa"
                              className="p-1.5 rounded-lg bg-teal-50 text-teal-700 hover:bg-teal-100"
                            >
                              <Edit3 className="w-4 h-4" />
                            </button>
                          </>
                        )}
                        {canDeleteEntity() && (
                          <button
                            type="button"
                            onClick={() => setDeleteTarget(dest)}
                            title="Xóa địa điểm"
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

      {/* Modal Add / Edit Destination */}
      <ModalDialog
        isOpen={isModalOpen}
        title={
          formData.id ? `Chỉnh sửa Địa điểm: ${formData.name}` : "Thêm Địa điểm Du lịch Mới"
        }
        subtitle="Mọi thông tin nguồn dữ liệu, tọa độ GPS và bản quyền ảnh sẽ hiển thị minh bạch trên ứng dụng"
        onClose={() => setIsModalOpen(false)}
        maxWidth="max-w-3xl"
      >
        <form onSubmit={handleSave} className="space-y-4 text-xs">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="sm:col-span-2">
              <label className="block font-bold text-slate-700 mb-1">Tên địa điểm du lịch *</label>
              <input
                type="text"
                required
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="VD: Dinh Độc Lập (Hội trường Thống Nhất)"
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
                className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white disabled:bg-slate-100"
              >
                {provinces.map((p) => (
                  <option key={p.id} value={p.id}>
                    {p.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block font-bold text-slate-700 mb-1">Danh mục địa điểm</label>
              <select
                value={formData.category_id}
                onChange={(e) =>
                  setFormData({ ...formData, category_id: Number(e.target.value) })
                }
                className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white"
              >
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
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
          </div>

          <div>
            <label className="block font-bold text-slate-700 mb-1">Địa chỉ chi tiết *</label>
            <input
              type="text"
              required
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              placeholder="VD: 135 Nam Kỳ Khởi Nghĩa, Phường Bến Thành, Quận 1, TP. Hồ Chí Minh"
              className="w-full px-3 py-2 border border-slate-300 rounded-xl"
            />
          </div>

          <div>
            <label className="block font-bold text-slate-700 mb-1">Mô tả chi tiết *</label>
            <textarea
              rows={3}
              required
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-3 py-2 border border-slate-300 rounded-xl"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div>
              <label className="block font-bold text-slate-700 mb-1">Giờ mở cửa tham khảo</label>
              <input
                type="text"
                value={formData.opening_hours}
                onChange={(e) => setFormData({ ...formData, opening_hours: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
            <div>
              <label className="block font-bold text-slate-700 mb-1">Thông tin giá vé</label>
              <input
                type="text"
                value={formData.ticket_price_info}
                onChange={(e) => setFormData({ ...formData, ticket_price_info: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
            <div>
              <label className="block font-bold text-slate-700 mb-1">
                Thời lượng tham quan (phút)
              </label>
              <input
                type="number"
                value={formData.recommended_duration_mins}
                onChange={(e) =>
                  setFormData({ ...formData, recommended_duration_mins: e.target.value })
                }
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
          </div>

          {/* Nguồn dữ liệu & Bản quyền ảnh (Mục 11) */}
          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-3">
            <h4 className="font-extrabold text-slate-800">
              Thông Tin Nguồn Dữ Liệu & Bản Quyền Hình Ảnh (Mục 11)
            </h4>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Nguồn dữ liệu</label>
                <select
                  value={formData.data_source}
                  onChange={(e) => setFormData({ ...formData, data_source: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white"
                >
                  <option value="internal">Nội bộ dự án xác thực (internal)</option>
                  <option value="partner">Đối tác cung cấp (partner)</option>
                  <option value="api_provider">Dịch vụ bản đồ / API ngoài (api_provider)</option>
                </select>
              </div>
              <div className="sm:col-span-2">
                <label className="block font-semibold text-slate-700 mb-1">
                  Ghi công nguồn (Attribution)
                </label>
                <input
                  type="text"
                  value={formData.source_attribution}
                  onChange={(e) =>
                    setFormData({ ...formData, source_attribution: e.target.value })
                  }
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="sm:col-span-2">
                <div className="flex items-center justify-between mb-1">
                  <label className="block font-semibold text-slate-700">
                    URL Hình ảnh chính (Tự động tối ưu qua Cloudinary CDN)
                  </label>
                  <button
                    type="button"
                    onClick={async () => {
                      const res = await adminApi.uploadImageToCloudinary(
                        formData.image_url,
                        formData.name || "destination.jpg"
                      );
                      setFormData({ ...formData, image_url: res.thumbnail_url });
                      showToast(
                        "Đã chuẩn hóa URL ảnh qua Cloudinary CDN (c_fill,w_400,h_300,q_auto,f_auto)!"
                      );
                    }}
                    className="text-[11px] font-bold text-teal-700 hover:text-teal-800 underline"
                  >
                    ⚡ Tối ưu Cloudinary CDN
                  </button>
                </div>
                <input
                  type="url"
                  value={formData.image_url}
                  onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white"
                />
                <p className="text-[10px] text-slate-500 mt-1">
                  Backend tự động sinh URL Thumbnail{" "}
                  <code className="bg-white px-1 rounded">c_fill,w_400,h_300,q_auto,f_auto</code>{" "}
                  và ảnh chi tiết <code className="bg-white px-1 rounded">w_1200,q_auto,f_auto</code>.
                </p>
              </div>
              <div>
                <label className="block font-semibold text-slate-700 mb-1">Giấy phép ảnh</label>
                <select
                  value={formData.license_type}
                  onChange={(e) => setFormData({ ...formData, license_type: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white"
                >
                  <option value="owned">Thuộc dự án (owned)</option>
                  <option value="cc_by_sa">Creative Commons (cc_by_sa)</option>
                  <option value="partner_authorized">Đối tác cấp phép (partner_authorized)</option>
                </select>
              </div>
            </div>
          </div>

          {/* Tùy chọn Nổi bật & Tài trợ (Mục 12) */}
          <div className="flex flex-wrap items-center justify-between gap-4 pt-3 border-t border-slate-200">
            <div className="flex flex-wrap items-center gap-4">
              <label className="inline-flex items-center gap-2 font-semibold text-slate-700">
                <input
                  type="checkbox"
                  checked={formData.is_featured}
                  onChange={(e) => setFormData({ ...formData, is_featured: e.target.checked })}
                />
                Địa điểm nổi bật
              </label>

              <label className="inline-flex items-center gap-2 font-semibold text-amber-800">
                <input
                  type="checkbox"
                  checked={formData.is_sponsored}
                  onChange={(e) => setFormData({ ...formData, is_sponsored: e.target.checked })}
                />
                Nội dung Đối tác / Tài trợ (Gắn nhãn minh bạch)
              </label>
            </div>

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
                Lưu Địa Điểm
              </button>
            </div>
          </div>
        </form>
      </ModalDialog>

      {/* Confirm Delete Modal */}
      <ConfirmDeleteModal
        isOpen={Boolean(deleteTarget)}
        title="Xác nhận xóa Địa điểm du lịch"
        itemName={deleteTarget?.name}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={handleConfirmDelete}
      />
    </div>
  );
}
