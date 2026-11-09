import React, { useCallback, useEffect, useState } from "react";
import { AuthProvider, useAuth } from "../hooks/useAuth";
import AdminLayout from "../layouts/AdminLayout";
import LoginPage from "../pages/auth/LoginPage";
import AppRoutes from "../routes/AppRoutes";
import TwoFactorSetupModal from "../components/TwoFactorSetupModal";
import { adminApi, DEMO_MODE } from "../services/api/client";
import { INITIAL_ADMIN_DATA } from "../services/api/mockAdminData";

const EMPTY_SNAPSHOT = {
  mode: DEMO_MODE ? "local" : "loading",
  dashboard: {},
  provinces: [],
  destinations: [],
  localFoods: [],
  restaurants: [],
  itineraries: [],
  users: [],
  reports: [],
  auditLogs: [],
  roles: [],
  categories: [],
};

function AdminShell() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState("dashboard");
  const [snapshot, setSnapshot] = useState(
    DEMO_MODE ? { ...EMPTY_SNAPSHOT, ...INITIAL_ADMIN_DATA } : EMPTY_SNAPSHOT
  );
  const [toast, setToast] = useState(null);
  const [show2faSetup, setShow2faSetup] = useState(false);

  const showToast = useCallback((message, type = "success") => {
    setToast({ message, type });
    setTimeout(() => {
      setToast(null);
    }, 3800);
  }, []);

  const loadSnapshot = useCallback(async () => {
    try {
      const data = await adminApi.fetchAllSnapshot();
      setSnapshot(data);
    } catch (err) {
      setSnapshot((prev) => ({ ...prev, mode: "error" }));
      showToast(
        err?.message || "Không tải được dữ liệu từ backend. Vui lòng thử lại.",
        "error"
      );
    }
  }, [showToast]);

  useEffect(() => {
    if (user) {
      loadSnapshot();
    }
  }, [user, loadSnapshot]);

  if (!user) {
    return (
      <LoginPage
        onLoginSuccess={(loggedUser) => {
          showToast(`Chào mừng ${loggedUser.full_name} (${loggedUser.role})`);
          loadSnapshot();
        }}
      />
    );
  }

  const pendingReportsCount = (snapshot.reports || []).filter(
    (r) => r.status === "pending"
  ).length;

  return (
    <>
      {toast && (
        <div
          className={`fixed bottom-5 right-5 z-50 px-4 py-3 rounded-xl shadow-xl border text-xs font-bold transition-all ${
            toast.type === "error"
              ? "bg-rose-600 text-white border-rose-700"
              : "bg-slate-900 text-white border-slate-700"
          }`}
        >
          {toast.message}
        </div>
      )}

      {user && user.totp_enabled === false && (
        <div className="flex flex-wrap items-center justify-between gap-2 bg-amber-50 border-b border-amber-200 px-4 py-2 text-xs text-amber-900">
          <span className="font-semibold">
            Tài khoản chưa bật 2FA. Nên bật trước khi vận hành production.
          </span>
          <button
            onClick={() => setShow2faSetup(true)}
            className="rounded-lg bg-amber-500 px-3 py-1.5 font-bold text-white hover:bg-amber-600"
          >
            Thiết lập 2FA
          </button>
        </div>
      )}

      <TwoFactorSetupModal
        open={show2faSetup}
        onClose={() => setShow2faSetup(false)}
      />

      <AdminLayout
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        connectionMode={snapshot.mode}
        pendingReportsCount={pendingReportsCount}
        onRefreshData={loadSnapshot}
        showToast={showToast}
      >
        <AppRoutes
          activeTab={activeTab}
          setActiveTab={setActiveTab}
          snapshot={snapshot}
          onRefresh={loadSnapshot}
          showToast={showToast}
        />
      </AdminLayout>
    </>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <AdminShell />
    </AuthProvider>
  );
}
