import React, { createContext, useContext, useState } from "react";
import { adminApi, DEMO_MODE } from "../services/api/client";

const AuthContext = createContext(null);

const SAVED_USER_KEY = "tripflow_admin_current_user";

export const DEMO_ADMIN_ACCOUNTS = DEMO_MODE
  ? [
      {
    label: "Super Admin (Toàn quyền)",
    email: "admin@tripflow.vn",
    password: "Admin@123",
    role: "super_admin",
    assigned_province_id: null,
    badgeColor: "bg-teal-600 text-white",
    desc: "Quản lý toàn bộ hệ thống, phân quyền RBAC & Audit Logs",
  },
  {
    label: "Content Admin (Toàn quốc)",
    email: "content@tripflow.vn",
    password: "Content@123",
    role: "content_admin",
    assigned_province_id: null,
    badgeColor: "bg-blue-600 text-white",
    desc: "Quản lý & duyệt xuất bản địa điểm, món ăn, nhà hàng các tỉnh",
  },
  {
    label: "HCM Province Editor (Chỉ TP.HCM)",
    email: "hcm.editor@tripflow.vn",
    password: "Editor@123",
    role: "province_editor",
    assigned_province_id: 1,
    badgeColor: "bg-amber-600 text-white",
    desc: "Chỉ được tạo/sửa dữ liệu thuộc TP. Hồ Chí Minh (province_id=1)",
  },
  {
    label: "Moderator (Kiểm duyệt báo sai)",
    email: "mod@tripflow.vn",
    password: "Mod@123",
    role: "moderator",
    assigned_province_id: null,
    badgeColor: "bg-purple-600 text-white",
    desc: "Chuyên trách xử lý đánh giá & báo cáo sai thông tin từ du khách",
  },
]
  : [];

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    try {
      const saved = localStorage.getItem(SAVED_USER_KEY);
      if (saved) return JSON.parse(saved);
    } catch {
      // ignore
    }
    // Không auto-login: bắt buộc đăng nhập thật bằng tài khoản quản trị.
    return null;
  });

  const login = async (email, password, otpCode = "") => {
    const res = await adminApi.login(email, password, otpCode);
    setUser(res.user);
    localStorage.setItem(SAVED_USER_KEY, JSON.stringify(res.user));
    return res.user;
  };

  const quickSwitchRole = async (demoAccount) => {
    return login(demoAccount.email, demoAccount.password);
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem(SAVED_USER_KEY);
    localStorage.removeItem("tripflow_admin_jwt_token");
  };

  /**
   * Kiểm tra quyền thao tác theo ma trận RBAC Mục 6.2
   */
  const canManageProvince = (provinceId) => {
    if (!user) return false;
    if (user.role === "super_admin" || user.role === "content_admin") return true;
    if (user.role === "province_editor") {
      return Number(user.assigned_province_id) === Number(provinceId);
    }
    return false;
  };

  const canDeleteEntity = () => {
    if (!user) return false;
    return user.role === "super_admin" || user.role === "content_admin";
  };

  const canManageUsers = () => {
    return user?.role === "super_admin";
  };

  const canModerateReports = () => {
    if (!user) return false;
    return ["super_admin", "content_admin", "moderator"].includes(user.role);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        login,
        logout,
        quickSwitchRole,
        canManageProvince,
        canDeleteEntity,
        canManageUsers,
        canModerateReports,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
