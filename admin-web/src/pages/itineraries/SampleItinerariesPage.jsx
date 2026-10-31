import React, { useState } from "react";
import {
  ArrowDown,
  ArrowUp,
  Edit3,
  MapPin,
  Plus,
  Route,
  Trash2,
  UtensilsCrossed,
} from "lucide-react";
import {
  ConfirmDeleteModal,
  ModalDialog,
  RbacNoticeBanner,
  StatusBadge,
} from "../../components/CommonUI";
import { useAuth } from "../../hooks/useAuth";
import { adminApi } from "../../services/api/client";

export default function SampleItinerariesPage({
  itineraries,
  provinces,
  destinations,
  restaurants,
  onRefresh,
  showToast,
}) {
  const { user, canManageProvince, canDeleteEntity } = useAuth();

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);

  const [formData, setFormData] = useState({
    id: null,
    province_id: 1,
    title: "",
    description: "",
    total_days: 1,
    is_template: true,
    status: "active",
    stops: [],
  });

  const openAddModal = () => {
    setFormData({
      id: null,
      province_id: user?.assigned_province_id || 1,
      title: "",
      description: "",
      total_days: 1,
      is_template: true,
      status: "active",
      stops: [
        {
          day_number: 1,
          stop_order: 1,
          stop_type: "destination",
          reference_id: 1,
          title: "Dinh Độc Lập (Hội trường Thống Nhất)",
          address: "135 Nam Kỳ Khởi Nghĩa, Quận 1, TP.HCM",
          latitude: 10.777,
          longitude: 106.6953,
          planned_time: "08:00 - 10:00",
          duration_mins: 120,
          notes: "Tham quan dinh thự lịch sử buổi sáng.",
        },
      ],
    });
    setIsModalOpen(true);
  };

  const openEditModal = (itin) => {
    setFormData({
      ...itin,
      stops: (itin.stops || []).map((s, idx) => ({
        ...s,
        stop_order: s.stop_order || idx + 1,
      })),
    });
    setIsModalOpen(true);
  };

  const addStopFromEntity = (type, entityId) => {
    if (!entityId) return;
    let item = null;
    if (type === "destination") {
      item = destinations.find((d) => Number(d.id) === Number(entityId));
    } else {
      item = restaurants.find((r) => Number(r.id) === Number(entityId));
    }
    if (!item) return;

    const nextOrder = (formData.stops?.length || 0) + 1;
    const newStop = {
      day_number: 1,
      stop_order: nextOrder,
      stop_type: type,
      reference_id: item.id,
      title: item.name,
      address: item.address,
      latitude: item.latitude,
      longitude: item.longitude,
      planned_time: type === "restaurant" ? "12:00 - 13:30" : "09:00 - 10:30",
      duration_mins: 90,
      notes: type === "restaurant" ? "Điểm dừng thưởng thức ẩm thực trên lộ trình" : "Tham quan chụp ảnh",
    };

    setFormData({
      ...formData,
      stops: [...(formData.stops || []), newStop],
    });
  };

  const moveStop = (index, direction) => {
    const list = [...(formData.stops || [])];
    const targetIdx = index + direction;
    if (targetIdx < 0 || targetIdx >= list.length) return;
    const temp = list[index];
    list[index] = list[targetIdx];
    list[targetIdx] = temp;
    const reordered = list.map((s, idx) => ({ ...s, stop_order: idx + 1 }));
    setFormData({ ...formData, stops: reordered });
  };

  const removeStop = (index) => {
    const list = (formData.stops || []).filter((_, idx) => idx !== index);
    const reordered = list.map((s, idx) => ({ ...s, stop_order: idx + 1 }));
    setFormData({ ...formData, stops: reordered });
  };

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      await adminApi.saveSampleItinerary(
        {
          ...formData,
          province_id: Number(formData.province_id),
          total_days: Number(formData.total_days || 1),
          is_template: true,
        },
        user
      );
      showToast(`Đã lưu lịch trình mẫu: ${formData.title}`);
      setIsModalOpen(false);
      onRefresh();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  const handleConfirmDelete = async () => {
    if (!deleteTarget) return;
    try {
      await adminApi.deleteSampleItinerary(deleteTarget.id, deleteTarget.title, user);
      showToast(`Đã xóa lịch trình mẫu "${deleteTarget.title}"`);
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
            <Route className="w-6 h-6 text-teal-600" />
            Quản Lý Lịch Trình Mẫu Gợi Ý ({itineraries.length})
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Thiết kế các lịch trình mẫu theo tỉnh/thành kết hợp Địa điểm tham quan và Nhà hàng ăn
            uống để du khách áp dụng 1 chạm trên ứng dụng.
          </p>
        </div>

        {user?.role !== "moderator" && (
          <button
            type="button"
            onClick={openAddModal}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-teal-600 hover:bg-teal-700 text-white text-xs font-bold shadow-sm"
          >
            <Plus className="w-4 h-4" />
            Tạo Lịch trình mẫu mới
          </button>
        )}
      </div>

      <div className="space-y-5">
        {itineraries.map((itin) => {
          const canEdit = canManageProvince(itin.province_id);
          return (
            <div
              key={itin.id}
              className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xs"
            >
              <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4 pb-4 border-b border-slate-100">
                <div>
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="px-2.5 py-0.5 rounded-md bg-teal-50 text-teal-700 text-xs font-bold">
                      {itin.province_name || "TP. Hồ Chí Minh"}
                    </span>
                    <span className="px-2.5 py-0.5 rounded-md bg-amber-50 text-amber-800 text-xs font-bold">
                      {itin.total_days} Ngày • {itin.stops?.length || 0} Điểm dừng
                    </span>
                    <StatusBadge status={itin.status} />
                  </div>
                  <h3 className="text-lg font-extrabold text-slate-900 mt-2">{itin.title}</h3>
                  <p className="text-xs text-slate-600 mt-1">{itin.description}</p>
                </div>

                <div className="flex items-center gap-2 shrink-0">
                  {canEdit && (
                    <button
                      type="button"
                      onClick={() => openEditModal(itin)}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-teal-50 text-teal-700 text-xs font-bold hover:bg-teal-100"
                    >
                      <Edit3 className="w-3.5 h-3.5" /> Biên tập điểm dừng
                    </button>
                  )}
                  {canDeleteEntity() && (
                    <button
                      type="button"
                      onClick={() => setDeleteTarget(itin)}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-rose-50 text-rose-600 text-xs font-bold hover:bg-rose-100"
                    >
                      <Trash2 className="w-3.5 h-3.5" /> Xóa
                    </button>
                  )}
                </div>
              </div>

              {/* Timeline Stops */}
              <div className="mt-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                {(itin.stops || []).map((stop, idx) => (
                  <div
                    key={stop.id || idx}
                    className="p-3.5 rounded-xl bg-slate-50 border border-slate-200/80 flex items-start gap-3"
                  >
                    <div
                      className={`w-7 h-7 rounded-lg flex items-center justify-center text-white text-xs font-bold shrink-0 ${
                        stop.stop_type === "restaurant" ? "bg-amber-500" : "bg-teal-600"
                      }`}
                    >
                      {idx + 1}
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-1.5">
                        {stop.stop_type === "restaurant" ? (
                          <UtensilsCrossed className="w-3.5 h-3.5 text-amber-600 shrink-0" />
                        ) : (
                          <MapPin className="w-3.5 h-3.5 text-teal-600 shrink-0" />
                        )}
                        <span className="text-xs font-bold text-slate-900 truncate">
                          {stop.title}
                        </span>
                      </div>
                      <p className="text-[11px] text-slate-500 mt-0.5 truncate">{stop.address}</p>
                      <span className="inline-block mt-1 text-[10px] font-semibold px-2 py-0.5 rounded bg-white border border-slate-200 text-slate-600">
                        Ngày {stop.day_number} • {stop.planned_time}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      {/* Modal Add / Edit Sample Itinerary */}
      <ModalDialog
        isOpen={isModalOpen}
        title={formData.id ? "Biên tập Lịch trình mẫu" : "Tạo Lịch trình Mẫu Mới"}
        subtitle="Thêm, xóa và đổi thứ tự các điểm dừng trong lịch trình gợi ý"
        onClose={() => setIsModalOpen(false)}
        maxWidth="max-w-3xl"
      >
        <form onSubmit={handleSave} className="space-y-4 text-xs">
          <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
            <div className="sm:col-span-2">
              <label className="block font-bold text-slate-700 mb-1">Tiêu đề Lịch trình *</label>
              <input
                type="text"
                required
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
            <div>
              <label className="block font-bold text-slate-700 mb-1">Tỉnh / Thành</label>
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
            <div>
              <label className="block font-bold text-slate-700 mb-1">Số ngày</label>
              <input
                type="number"
                min={1}
                max={7}
                value={formData.total_days}
                onChange={(e) => setFormData({ ...formData, total_days: e.target.value })}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl"
              />
            </div>
          </div>

          <div>
            <label className="block font-bold text-slate-700 mb-1">Mô tả ngắn</label>
            <textarea
              rows={2}
              value={formData.description || ""}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              className="w-full px-3 py-2 border border-slate-300 rounded-xl"
            />
          </div>

          {/* Quick Add Stop Selector */}
          <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200 grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block font-bold text-teal-800 mb-1">
                + Chèn nhanh Địa điểm du lịch
              </label>
              <select
                defaultValue=""
                onChange={(e) => {
                  addStopFromEntity("destination", e.target.value);
                  e.target.value = "";
                }}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white"
              >
                <option value="">-- Chọn địa điểm để thêm --</option>
                {destinations
                  .filter((d) => Number(d.province_id) === Number(formData.province_id))
                  .map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.name}
                    </option>
                  ))}
              </select>
            </div>

            <div>
              <label className="block font-bold text-amber-800 mb-1">
                + Chèn nhanh Nhà hàng ăn uống
              </label>
              <select
                defaultValue=""
                onChange={(e) => {
                  addStopFromEntity("restaurant", e.target.value);
                  e.target.value = "";
                }}
                className="w-full px-3 py-2 border border-slate-300 rounded-xl bg-white"
              >
                <option value="">-- Chọn nhà hàng để thêm --</option>
                {restaurants
                  .filter((r) => Number(r.province_id) === Number(formData.province_id))
                  .map((r) => (
                    <option key={r.id} value={r.id}>
                      {r.name}
                    </option>
                  ))}
              </select>
            </div>
          </div>

          {/* Stops Reorder List */}
          <div className="space-y-2 max-h-64 overflow-y-auto">
            {(formData.stops || []).map((st, idx) => (
              <div
                key={idx}
                className="flex items-center justify-between gap-3 p-3 rounded-xl border border-slate-200 bg-white"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <span className="w-6 h-6 rounded-full bg-slate-900 text-white font-bold flex items-center justify-center shrink-0">
                    {idx + 1}
                  </span>
                  <div className="min-w-0">
                    <p className="font-bold text-slate-900 truncate">{st.title}</p>
                    <p className="text-[11px] text-slate-500 truncate">
                      {st.stop_type === "restaurant" ? "🍴 Nhà hàng" : "📍 Địa điểm"} •{" "}
                      {st.planned_time}
                    </p>
                  </div>
                </div>

                <div className="flex items-center gap-1 shrink-0">
                  <button
                    type="button"
                    onClick={() => moveStop(idx, -1)}
                    disabled={idx === 0}
                    className="p-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 disabled:opacity-30"
                  >
                    <ArrowUp className="w-3.5 h-3.5" />
                  </button>
                  <button
                    type="button"
                    onClick={() => moveStop(idx, 1)}
                    disabled={idx === (formData.stops?.length || 0) - 1}
                    className="p-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 disabled:opacity-30"
                  >
                    <ArrowDown className="w-3.5 h-3.5" />
                  </button>
                  <button
                    type="button"
                    onClick={() => removeStop(idx)}
                    className="p-1.5 rounded-lg bg-rose-50 text-rose-600 hover:bg-rose-100"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            ))}
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
              className="px-5 py-2 rounded-xl bg-teal-600 hover:bg-teal-700 text-white font-bold shadow-sm"
            >
              Lưu Lịch Trình Mẫu
            </button>
          </div>
        </form>
      </ModalDialog>

      <ConfirmDeleteModal
        isOpen={Boolean(deleteTarget)}
        title="Xác nhận xóa Lịch trình mẫu"
        itemName={deleteTarget?.title}
        onCancel={() => setDeleteTarget(null)}
        onConfirm={handleConfirmDelete}
      />
    </div>
  );
}
