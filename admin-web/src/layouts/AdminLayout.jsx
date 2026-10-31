import React from "react";
import {
  Compass,
  Flag,
  Handshake,
  LayoutDashboard,
  LogOut,
  Map,
  MapPin,
  RefreshCw,
  Route,
  ShieldCheck,
  Soup,
  Users,
  UtensilsCrossed,
  Wifi,
  WifiOff,
} from "lucide-react";
import { DEMO_ADMIN_ACCOUNTS, useAuth } from "../hooks/useAuth";

export const NAV_ITEMS = [
  { id: "dashboard", label: "Dashboard Tổng quan", icon: LayoutDashboard },
  { id: "provinces", label: "Tỉnh / Thành phố", icon: Map },
  { id: "destinations", label: "Địa điểm du lịch", icon: MapPin },
  { id: "local-foods", label: "Đặc sản / Món ăn", icon: Soup },
  { id: "restaurants", label: "Nhà hàng & Quán ăn", icon: UtensilsCrossed },
  { id: "itineraries", label: "Lịch trình mẫu", icon: Route },
  { id: "users", label: "Quản lý Người dùng", icon: Users },
  { id: "reports", label: "Đánh giá & Báo sai", icon: Flag, badgeKey: "pending_reports" },
  { id: "partners", label: "Đối tác & Tài trợ", icon: Handshake },
  { id: "settings", label: "Quản trị & Audit Logs", icon: ShieldCheck },
];

export default function AdminLayout({
  activeTab,
  setActiveTab,
  connectionMode,
  pendingReportsCount,
  onRefreshData,
  showToast,
  children,
}) {
  const { user, logout, quickSwitchRole } = useAuth();

  const handleRoleSwitch = async (e) => {
    const email = e.target.value;
    const found = DEMO_ADMIN_ACCOUNTS.find((a) => a.email === email);
    if (!found) return;
    try {
      const switchedUser = await quickSwitchRole(found);
      showToast(
        `Đã chuyển nhanh sang tài khoản: ${switchedUser.full_name} (Role: ${switchedUser.role})`
      );
      onRefreshData();
    } catch (err) {
      showToast(err.message, "error");
    }
  };

  return (
    <div className="min-h-screen flex bg-slate-50">
      {/* Sidebar */}
      <aside className="w-68 bg-slate-900 text-slate-200 flex flex-col shrink-0 border-r border-slate-800">
        <div className="px-6 py-5 flex items-center gap-3 border-b border-slate-800">
          <div className="w-10 h-10 rounded-xl bg-teal-500 flex items-center justify-center text-white shadow-lg shadow-teal-500/25">
            <Compass className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-lg font-extrabold tracking-tight text-white">TripFlow Admin</h1>
            <p className="text-xs text-teal-400 font-medium">Travel Discovery CMS</p>
          </div>
        </div>

        {/* Navigation Links */}
        <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
          {NAV_ITEMS.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            const badgeVal = item.badgeKey === "pending_reports" ? pendingReportsCount : 0;

            return (
              <button
                key={item.id}
                type="button"
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                  isActive
                    ? "bg-teal-600 text-white shadow-md shadow-teal-900/40"
                    : "text-slate-400 hover:bg-slate-800/80 hover:text-white"
                }`}
              >
                <span className="flex items-center gap-3">
                  <Icon className="w-4 h-4 shrink-0" />
                  <span>{item.label}</span>
                </span>
                {badgeVal > 0 && (
                  <span
                    className={`px-2 py-0.5 text-xs font-bold rounded-full ${
                      isActive ? "bg-white text-teal-700" : "bg-rose-500 text-white"
                    }`}
                  >
                    {badgeVal}
                  </span>
                )}
              </button>
            );
          })}
        </nav>

        {/* Current User Profile Card */}
        <div className="p-4 border-t border-slate-800 bg-slate-950/60">
          <div className="flex items-center justify-between">
            <div className="min-w-0">
              <p className="text-xs font-semibold text-white truncate">{user?.full_name}</p>
              <p className="text-[11px] text-slate-400 truncate">{user?.email}</p>
            </div>
            <button
              type="button"
              onClick={logout}
              title="Đăng xuất"
              className="p-2 text-slate-400 hover:text-rose-400 hover:bg-slate-800 rounded-lg transition-colors"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
          <div className="mt-2.5 flex items-center gap-2">
            <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-bold uppercase tracking-wider bg-teal-500/20 text-teal-300 border border-teal-500/30">
              {user?.role}
            </span>
            {user?.assigned_province_id && (
              <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[11px] font-semibold bg-amber-500/20 text-amber-300 border border-amber-500/30">
                TP.HCM (ID: {user.assigned_province_id})
              </span>
            )}
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        {/* Topbar */}
        <header className="h-16 bg-white border-b border-slate-200 px-6 flex items-center justify-between sticky top-0 z-30">
          <div className="flex items-center gap-4">
            <h2 className="text-base font-bold text-slate-800">
              {NAV_ITEMS.find((n) => n.id === activeTab)?.label || "Quản trị"}
            </h2>
            <span
              className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold border ${
                connectionMode === "api"
                  ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                  : "bg-amber-50 text-amber-700 border-amber-200"
              }`}
            >
              {connectionMode === "api" ? (
                <>
                  <Wifi className="w-3.5 h-3.5 text-emerald-600" />
                  Đồng bộ FastAPI Backend (:8000)
                </>
              ) : (
                <>
                  <WifiOff className="w-3.5 h-3.5 text-amber-600" />
                  Chế độ Local Fallback Store (TP.HCM)
                </>
              )}
            </span>
          </div>

          <div className="flex items-center gap-3">
            {/* Quick Role Switcher for Testing RBAC */}
            <div className="flex items-center gap-2 text-xs">
              <span className="text-slate-500 font-medium hidden md:inline">
                Chuyển nhanh quyền RBAC:
              </span>
              <select
                value={user?.email || ""}
                onChange={handleRoleSwitch}
                className="text-xs font-semibold bg-slate-100 border border-slate-300 text-slate-800 rounded-lg px-2.5 py-1.5 focus:outline-none focus:ring-2 focus:ring-teal-500"
              >
                {DEMO_ADMIN_ACCOUNTS.map((acc) => (
                  <option key={acc.email} value={acc.email}>
                    {acc.label}
                  </option>
                ))}
              </select>
            </div>

            <button
              type="button"
              onClick={onRefreshData}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 transition-colors"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              Làm mới
            </button>
          </div>
        </header>

        {/* Page Body */}
        <main className="flex-1 p-6 overflow-y-auto">{children}</main>
      </div>
    </div>
  );
}
