import axios from "axios";
import { INITIAL_ADMIN_DATA } from "./mockAdminData";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://localhost:8000/api/v1";
const LOCAL_STORE_KEY = "tripflow_admin_fallback_store_v2";
const TOKEN_KEY = "tripflow_admin_jwt_token";

const http = axios.create({
  baseURL: API_BASE_URL,
  timeout: 4500,
});

http.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

function getLocalStore() {
  try {
    const raw = localStorage.getItem(LOCAL_STORE_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (parsed && Array.isArray(parsed.localFoods) && Array.isArray(parsed.destinations)) {
        return parsed;
      }
    }
  } catch (e) {
    console.warn("Could not parse local fallback store:", e);
  }
  const cloned = JSON.parse(JSON.stringify(INITIAL_ADMIN_DATA));
  localStorage.setItem(LOCAL_STORE_KEY, JSON.stringify(cloned));
  return cloned;
}

function saveLocalStore(store) {
  localStorage.setItem(LOCAL_STORE_KEY, JSON.stringify(store));
}

function appendLocalAuditLog(store, actor, action, entityType, entityId, summary, changes = {}) {
  const newLog = {
    id: Date.now(),
    actor_id: actor?.id || 1,
    actor_email: actor?.email || "admin@tripflow.vn",
    actor_role: actor?.role || "super_admin",
    action,
    entity_type: entityType,
    entity_id: entityId,
    summary,
    changes_json: JSON.stringify(changes),
    created_at: new Date().toISOString(),
  };
  store.auditLogs = [newLog, ...(store.auditLogs || [])];
}

function enforceLocalRbac(actor, requiredRoles, provinceId = null) {
  if (!actor) {
    throw new Error("Vui lòng đăng nhập tài khoản quản trị.");
  }
  if (requiredRoles && !requiredRoles.includes(actor.role)) {
    throw new Error(
      `Từ chối truy cập (403 Forbidden): Vai trò '${actor.role}' không có quyền thực hiện thao tác này.`
    );
  }
  if (
    actor.role === "province_editor" &&
    provinceId !== null &&
    Number(actor.assigned_province_id) !== Number(provinceId)
  ) {
    throw new Error(
      `Từ chối truy cập (403 Forbidden): Bạn là Biên tập viên tỉnh/thành (province_id=${actor.assigned_province_id}) và không được sửa dữ liệu tỉnh khác.`
    );
  }
}

export const adminApi = {
  isBackendConnected: false,

  async checkBackendHealth() {
    try {
      await axios.get(API_BASE_URL.replace("/api/v1", "/health"), { timeout: 2500 });
      this.isBackendConnected = true;
      return true;
    } catch {
      this.isBackendConnected = false;
      return false;
    }
  },

  async login(email, password) {
    try {
      const res = await http.post("/auth/login", { email, password });
      this.isBackendConnected = true;
      if (res.data?.access_token) {
        localStorage.setItem(TOKEN_KEY, res.data.access_token);
      }
      return res.data;
    } catch (err) {
      if (err.response) {
        throw new Error(err.response.data?.detail || "Đăng nhập thất bại.");
      }
      // Fallback sang dữ liệu cục bộ nếu chưa bật Backend FastAPI
      this.isBackendConnected = false;
      const store = getLocalStore();
      const found = store.users.find((u) => u.email.toLowerCase() === email.trim().toLowerCase());
      if (!found) {
        throw new Error("Email không tồn tại trong hệ thống.");
      }
      const mockToken = `local_demo_token_${found.id}_${Date.now()}`;
      localStorage.setItem(TOKEN_KEY, mockToken);
      appendLocalAuditLog(
        store,
        found,
        "LOGIN",
        "user",
        found.id,
        `Quản trị viên ${found.email} (${found.role}) đăng nhập hệ thống.`
      );
      saveLocalStore(store);
      return {
        access_token: mockToken,
        token_type: "bearer",
        user: found,
      };
    }
  },

  async fetchAllSnapshot() {
    try {
      const [
        dashRes,
        provRes,
        destRes,
        foodRes,
        restRes,
        itinRes,
        userRes,
        repRes,
        logRes,
        roleRes,
      ] = await Promise.all([
        http.get("/admin/dashboard"),
        http.get("/admin/provinces"),
        http.get("/admin/destinations"),
        http.get("/admin/local-foods"),
        http.get("/admin/restaurants"),
        http.get("/itineraries?templates_only=false"),
        http.get("/admin/users"),
        http.get("/admin/reports"),
        http.get("/admin/audit-logs"),
        http.get("/admin/roles"),
      ]);
      this.isBackendConnected = true;
      return {
        mode: "api",
        dashboard: dashRes.data,
        provinces: provRes.data,
        destinations: destRes.data,
        localFoods: foodRes.data,
        restaurants: restRes.data,
        itineraries: itinRes.data,
        users: userRes.data,
        reports: repRes.data,
        auditLogs: logRes.data,
        roles: roleRes.data,
        categories: INITIAL_ADMIN_DATA.categories,
      };
    } catch {
      this.isBackendConnected = false;
      const store = getLocalStore();
      const sponsoredCount =
        store.destinations.filter((d) => d.is_sponsored).length +
        store.restaurants.filter((r) => r.is_sponsored).length;
      const internalCount =
        store.destinations.filter((d) => d.data_source === "internal").length +
        store.restaurants.filter((r) => r.data_source === "internal").length;
      const partnerCount =
        store.destinations.filter((d) => d.data_source === "partner").length +
        store.restaurants.filter((r) => r.data_source === "partner").length;
      const apiCount =
        store.destinations.filter((d) => d.data_source === "api_provider").length +
        store.restaurants.filter((r) => r.data_source === "api_provider").length;

      return {
        mode: "local",
        dashboard: {
          total_provinces: store.provinces.length,
          total_destinations: store.destinations.length,
          total_local_foods: store.localFoods.length,
          total_restaurants: store.restaurants.length,
          total_templates: store.itineraries.filter((i) => i.is_template).length,
          total_users: store.users.length,
          pending_reports: store.reports.filter((r) => r.status === "pending").length,
          sponsored_items_count: sponsoredCount,
          data_source_breakdown: {
            internal: internalCount,
            partner: partnerCount,
            api_provider: apiCount,
          },
          maps_api_quota: {
            provider: "goong_maps",
            daily_calls_used: 18,
            daily_budget_limit: 500,
            usage_percentage: 3.6,
            cache_hits: 42,
            corridor_rate_limit: "10/minute",
            max_corridor_radius_km: 10.0,
            max_itinerary_stops: 20,
            cloudinary_enabled: true,
            shapely_corridor_enabled: true,
            server_key_protected: true,
            alert_status: "healthy",
          },
          recent_audit_logs: store.auditLogs.slice(0, 10),
        },
        provinces: store.provinces,
        destinations: store.destinations,
        localFoods: store.localFoods,
        restaurants: store.restaurants,
        itineraries: store.itineraries,
        users: store.users,
        reports: store.reports,
        auditLogs: store.auditLogs,
        roles: store.roles,
        permissions: store.permissions || INITIAL_ADMIN_DATA.permissions,
        categories: store.categories || INITIAL_ADMIN_DATA.categories,
      };
    }
  },

  async uploadImageToCloudinary(imageUrl, filename = "tripflow_upload.jpg", folder = "tripflow/destinations") {
    try {
      const res = await http.post("/admin/upload-image", {
        image_url: imageUrl,
        filename,
        folder,
      });
      return res.data;
    } catch {
      const cleanUrl = imageUrl || "https://images.unsplash.com/photo-1583417319070-4a69db38a482";
      return {
        provider: "cloudinary",
        public_id: `${folder}/${filename.replace(/\.[^/.]+$/, "")}`,
        original_url: cleanUrl,
        thumbnail_url: `https://res.cloudinary.com/demo/image/fetch/c_fill,w_400,h_300,q_auto,f_auto/${cleanUrl}`,
        detail_url: `https://res.cloudinary.com/demo/image/fetch/w_1200,q_auto,f_auto/${cleanUrl}`,
        transformations: {
          thumbnail: "c_fill,w_400,h_300,q_auto,f_auto",
          detail: "w_1200,q_auto,f_auto",
        },
      };
    }
  },

  async saveProvince(payload, actor) {
    try {
      if (payload.id) {
        const res = await http.put(`/admin/provinces/${payload.id}`, payload);
        return res.data;
      } else {
        const res = await http.post("/admin/provinces", payload);
        return res.data;
      }
    } catch (err) {
      if (err.response) throw new Error(err.response.data?.detail || "Lỗi lưu tỉnh/thành.");
      enforceLocalRbac(actor, ["super_admin", "content_admin"]);
      const store = getLocalStore();
      if (payload.id) {
        store.provinces = store.provinces.map((p) =>
          p.id === payload.id ? { ...p, ...payload, updated_at: new Date().toISOString() } : p
        );
        appendLocalAuditLog(
          store,
          actor,
          "UPDATE",
          "province",
          payload.id,
          `Cập nhật tỉnh/thành phố: ${payload.name} (${payload.code})`,
          payload
        );
      } else {
        const newProv = {
          ...payload,
          id: Date.now(),
          updated_at: new Date().toISOString(),
          destination_count: 0,
          food_count: 0,
          restaurant_count: 0,
        };
        store.provinces.push(newProv);
        appendLocalAuditLog(
          store,
          actor,
          "CREATE",
          "province",
          newProv.id,
          `Thêm tỉnh/thành phố mới: ${newProv.name} (${newProv.code})`,
          payload
        );
      }
      saveLocalStore(store);
      return payload;
    }
  },

  async saveDestination(payload, actor) {
    try {
      if (payload.id) {
        const res = await http.put(`/admin/destinations/${payload.id}`, payload);
        return res.data;
      } else {
        const res = await http.post("/admin/destinations", payload);
        return res.data;
      }
    } catch (err) {
      if (err.response) throw new Error(err.response.data?.detail || "Lỗi lưu địa điểm.");
      enforceLocalRbac(
        actor,
        ["super_admin", "content_admin", "province_editor"],
        payload.province_id
      );
      const store = getLocalStore();
      const prov = store.provinces.find((p) => Number(p.id) === Number(payload.province_id));
      const cat = (store.categories || INITIAL_ADMIN_DATA.categories).find(
        (c) => Number(c.id) === Number(payload.category_id)
      );
      if (payload.id) {
        store.destinations = store.destinations.map((d) =>
          d.id === payload.id
            ? {
                ...d,
                ...payload,
                province_name: prov?.name || d.province_name,
                category_name: cat?.name || d.category_name,
                category_code: cat?.code || d.category_code,
                updated_at: new Date().toISOString(),
                last_verified_at: new Date().toISOString(),
              }
            : d
        );
        appendLocalAuditLog(
          store,
          actor,
          "UPDATE",
          "destination",
          payload.id,
          `Cập nhật địa điểm du lịch: ${payload.name}`,
          payload
        );
      } else {
        const newDest = {
          ...payload,
          id: Date.now(),
          province_name: prov?.name || "TP. Hồ Chí Minh",
          category_name: cat?.name || "Di tích lịch sử",
          category_code: cat?.code || "heritage",
          updated_at: new Date().toISOString(),
          last_verified_at: new Date().toISOString(),
          images:
            payload.images && payload.images.length > 0
              ? payload.images
              : [
                  {
                    id: Date.now(),
                    image_url:
                      "https://images.unsplash.com/photo-1583417319070-4a69db38a482?auto=format&fit=crop&w=1000&q=80",
                    caption: payload.name,
                    license_type: "owned",
                    credit_author: "TripFlow Studio",
                  },
                ],
        };
        store.destinations.unshift(newDest);
        appendLocalAuditLog(
          store,
          actor,
          "CREATE",
          "destination",
          newDest.id,
          `Thêm địa điểm du lịch mới: ${newDest.name}`,
          payload
        );
      }
      saveLocalStore(store);
      return payload;
    }
  },

  async deleteDestination(id, name, actor) {
    try {
      await http.delete(`/admin/destinations/${id}`);
      return true;
    } catch (err) {
      if (err.response) throw new Error(err.response.data?.detail || "Không thể xóa địa điểm.");
      enforceLocalRbac(actor, ["super_admin", "content_admin"]);
      const store = getLocalStore();
      store.destinations = store.destinations.filter((d) => d.id !== id);
      appendLocalAuditLog(
        store,
        actor,
        "DELETE",
        "destination",
        id,
        `Xóa địa điểm du lịch: ${name}`,
        { deleted_id: id }
      );
      saveLocalStore(store);
      return true;
    }
  },

  async saveLocalFood(payload, actor) {
    try {
      if (payload.id) {
        const res = await http.put(`/admin/local-foods/${payload.id}`, payload);
        return res.data;
      } else {
        const res = await http.post("/admin/local-foods", payload);
        return res.data;
      }
    } catch (err) {
      if (err.response) throw new Error(err.response.data?.detail || "Lỗi lưu món ăn.");
      enforceLocalRbac(
        actor,
        ["super_admin", "content_admin", "province_editor"],
        payload.province_id
      );
      const store = getLocalStore();
      const prov = store.provinces.find((p) => Number(p.id) === Number(payload.province_id));
      if (payload.id) {
        store.localFoods = store.localFoods.map((f) =>
          f.id === payload.id
            ? {
                ...f,
                ...payload,
                province_name: prov?.name || f.province_name,
                updated_at: new Date().toISOString(),
              }
            : f
        );
        appendLocalAuditLog(
          store,
          actor,
          "UPDATE",
          "local_food",
          payload.id,
          `Cập nhật đặc sản/món ăn: ${payload.name}`,
          payload
        );
      } else {
        const newFood = {
          ...payload,
          id: Date.now(),
          province_name: prov?.name || "TP. Hồ Chí Minh",
          updated_at: new Date().toISOString(),
        };
        store.localFoods.unshift(newFood);
        appendLocalAuditLog(
          store,
          actor,
          "CREATE",
          "local_food",
          newFood.id,
          `Thêm đặc sản/món ăn mới: ${newFood.name}`,
          payload
        );
      }
      saveLocalStore(store);
      return payload;
    }
  },

  async deleteLocalFood(id, name, actor) {
    try {
      await http.delete(`/admin/local-foods/${id}`);
      return true;
    } catch (err) {
      if (err.response) throw new Error(err.response.data?.detail || "Không thể xóa món ăn.");
      enforceLocalRbac(actor, ["super_admin", "content_admin"]);
      const store = getLocalStore();
      store.localFoods = store.localFoods.filter((f) => f.id !== id);
      appendLocalAuditLog(
        store,
        actor,
        "DELETE",
        "local_food",
        id,
        `Xóa đặc sản/món ăn: ${name}`,
        { deleted_id: id }
      );
      saveLocalStore(store);
      return true;
    }
  },

  async saveRestaurant(payload, actor) {
    try {
      if (payload.id) {
        const res = await http.put(`/admin/restaurants/${payload.id}`, payload);
        return res.data;
      } else {
        const res = await http.post("/admin/restaurants", payload);
        return res.data;
      }
    } catch (err) {
      if (err.response) throw new Error(err.response.data?.detail || "Lỗi lưu nhà hàng.");
      enforceLocalRbac(
        actor,
        ["super_admin", "content_admin", "province_editor"],
        payload.province_id
      );
      const store = getLocalStore();
      const prov = store.provinces.find((p) => Number(p.id) === Number(payload.province_id));
      if (payload.id) {
        store.restaurants = store.restaurants.map((r) =>
          r.id === payload.id
            ? {
                ...r,
                ...payload,
                province_name: prov?.name || r.province_name,
                last_updated_at: new Date().toISOString(),
              }
            : r
        );
        appendLocalAuditLog(
          store,
          actor,
          "UPDATE",
          "restaurant",
          payload.id,
          `Cập nhật thông tin nhà hàng: ${payload.name}`,
          payload
        );
      } else {
        const newRest = {
          ...payload,
          id: Date.now(),
          province_name: prov?.name || "TP. Hồ Chí Minh",
          last_updated_at: new Date().toISOString(),
        };
        store.restaurants.unshift(newRest);
        appendLocalAuditLog(
          store,
          actor,
          "CREATE",
          "restaurant",
          newRest.id,
          `Thêm nhà hàng mới: ${newRest.name}`,
          payload
        );
      }
      saveLocalStore(store);
      return payload;
    }
  },

  async deleteRestaurant(id, name, actor) {
    try {
      await http.delete(`/admin/restaurants/${id}`);
      return true;
    } catch (err) {
      if (err.response) throw new Error(err.response.data?.detail || "Không thể xóa nhà hàng.");
      enforceLocalRbac(actor, ["super_admin", "content_admin"]);
      const store = getLocalStore();
      store.restaurants = store.restaurants.filter((r) => r.id !== id);
      appendLocalAuditLog(
        store,
        actor,
        "DELETE",
        "restaurant",
        id,
        `Xóa nhà hàng: ${name}`,
        { deleted_id: id }
      );
      saveLocalStore(store);
      return true;
    }
  },

  async saveSampleItinerary(payload, actor) {
    try {
      if (payload.id) {
        const res = await http.put(`/admin/itineraries/${payload.id}`, payload);
        return res.data;
      } else {
        const res = await http.post("/admin/itineraries", payload);
        return res.data;
      }
    } catch (err) {
      if (err.response) throw new Error(err.response.data?.detail || "Lỗi lưu lịch trình mẫu.");
      enforceLocalRbac(
        actor,
        ["super_admin", "content_admin", "province_editor"],
        payload.province_id
      );
      const store = getLocalStore();
      const prov = store.provinces.find((p) => Number(p.id) === Number(payload.province_id));
      if (payload.id) {
        store.itineraries = store.itineraries.map((it) =>
          it.id === payload.id
            ? {
                ...it,
                ...payload,
                is_template: true,
                province_name: prov?.name || it.province_name,
                updated_at: new Date().toISOString(),
              }
            : it
        );
        appendLocalAuditLog(
          store,
          actor,
          "UPDATE",
          "itinerary",
          payload.id,
          `Cập nhật lịch trình mẫu: ${payload.title}`,
          payload
        );
      } else {
        const newItin = {
          ...payload,
          id: Date.now(),
          is_template: true,
          province_name: prov?.name || "TP. Hồ Chí Minh",
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };
        store.itineraries.unshift(newItin);
        appendLocalAuditLog(
          store,
          actor,
          "CREATE",
          "itinerary",
          newItin.id,
          `Tạo lịch trình mẫu mới: ${newItin.title}`,
          payload
        );
      }
      saveLocalStore(store);
      return payload;
    }
  },

  async deleteSampleItinerary(id, title, actor) {
    try {
      await http.delete(`/admin/itineraries/${id}`);
      return true;
    } catch (err) {
      if (err.response) throw new Error(err.response.data?.detail || "Không thể xóa lịch trình.");
      enforceLocalRbac(actor, ["super_admin", "content_admin"]);
      const store = getLocalStore();
      store.itineraries = store.itineraries.filter((i) => i.id !== id);
      appendLocalAuditLog(
        store,
        actor,
        "DELETE",
        "itinerary",
        id,
        `Xóa lịch trình mẫu: ${title}`,
        { deleted_id: id }
      );
      saveLocalStore(store);
      return true;
    }
  },

  async updateUserRole(userId, payload, actor) {
    try {
      const res = await http.put(`/admin/users/${userId}/role`, payload);
      return res.data;
    } catch (err) {
      if (err.response) throw new Error(err.response.data?.detail || "Lỗi cập nhật quyền.");
      enforceLocalRbac(actor, ["super_admin"]);
      const store = getLocalStore();
      store.users = store.users.map((u) => (u.id === userId ? { ...u, ...payload } : u));
      appendLocalAuditLog(
        store,
        actor,
        "UPDATE",
        "user",
        userId,
        `Cập nhật vai trò RBAC cho tài khoản ID=${userId} -> ${payload.role}`,
        payload
      );
      saveLocalStore(store);
      return payload;
    }
  },

  async resolveReport(reportId, payload, actor) {
    try {
      const res = await http.put(`/admin/reports/${reportId}`, payload);
      return res.data;
    } catch (err) {
      if (err.response) throw new Error(err.response.data?.detail || "Lỗi xử lý báo cáo.");
      enforceLocalRbac(actor, ["super_admin", "content_admin", "moderator"]);
      const store = getLocalStore();
      let targetName = "";
      store.reports = store.reports.map((rep) => {
        if (rep.id === reportId) {
          targetName = rep.target_name;
          return {
            ...rep,
            status: payload.status,
            moderator_note: payload.moderator_note,
            resolved_at: new Date().toISOString(),
          };
        }
        return rep;
      });
      appendLocalAuditLog(
        store,
        actor,
        payload.status === "resolved" ? "APPROVE" : "REJECT",
        "report",
        reportId,
        `Xử lý báo cáo #${reportId} (${targetName}): ${payload.status}`,
        payload
      );
      saveLocalStore(store);
      return payload;
    }
  },

  resetLocalStore() {
    localStorage.removeItem(LOCAL_STORE_KEY);
    return getLocalStore();
  },
};
