import React, { useCallback, useEffect, useState } from "react";
import { AuthProvider, useAuth } from "../hooks/useAuth";
import AdminLayout from "../layouts/AdminLayout";
import LoginPage from "../pages/auth/LoginPage";
import AppRoutes from "../routes/AppRoutes";
import { adminApi } from "../services/api/client";
import { INITIAL_ADMIN_DATA } from "../services/api/mockAdminData";

function AdminShell() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState("dashboard");
  const [snapshot, setSnapshot] = useState({
    mode: "local",
    dashboard: {},
    provinces: INITIAL_ADMIN_DATA.provinces,
    destinations: INITIAL_ADMIN_DATA.destinations,
    localFoods: INITIAL_ADMIN_DATA.localFoods,
    restaurants: INITIAL_ADMIN_DATA.restaurants,
    itineraries: INITIAL_ADMIN_DATA.itineraries,
    users: INITIAL_ADMIN_DATA.users,
    reports: INITIAL_ADMIN_DATA.reports,
    auditLogs: INITIAL_ADMIN_DATA.auditLogs,
    roles: INITIAL_ADMIN_DATA.roles,
    categories: INITIAL_ADMIN_DATA.categories,
  });
  const [toast, setToast] = useState(null);

  const showToast = useCallback((message, type = "success") => {
    setToast({ message, type });
    setTimeout(() => {
      setToast(null);
    }, 3800);
  }, []);

  const loadSnapshot = useCallback(async () => {
    const data = await adminApi.fetchAllSnapshot();
    setSnapshot(data);
  }, []);

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
