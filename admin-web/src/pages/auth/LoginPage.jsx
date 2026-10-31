import React, { useState } from "react";
import { Compass, KeyRound, Lock, Mail, ShieldCheck } from "lucide-react";
import { DEMO_ADMIN_ACCOUNTS, useAuth } from "../../hooks/useAuth";

export default function LoginPage({ onLoginSuccess }) {
  const { login } = useAuth();
  const [email, setEmail] = useState("admin@tripflow.vn");
  const [password, setPassword] = useState("Admin@123");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      const loggedUser = await login(email, password);
      onLoginSuccess?.(loggedUser);
    } catch (err) {
      setError(err.message || "Đăng nhập không thành công.");
    } finally {
      setLoading(false);
    }
  };

  const handleQuickFill = async (acc) => {
    setEmail(acc.email);
    setPassword(acc.password);
    setError("");
    setLoading(true);
    try {
      const loggedUser = await login(acc.email, acc.password);
      onLoginSuccess?.(loggedUser);
    } catch (err) {
      setError(err.message || "Đăng nhập không thành công.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
      <div className="max-w-4xl w-full grid grid-cols-1 lg:grid-cols-12 bg-white rounded-3xl shadow-2xl overflow-hidden border border-slate-800">
        {/* Left Brand Banner */}
        <div className="lg:col-span-5 bg-gradient-to-br from-teal-700 via-teal-800 to-slate-900 text-white p-8 flex flex-col justify-between">
          <div>
            <div className="inline-flex items-center gap-3 bg-white/10 backdrop-blur-xs px-4 py-2 rounded-2xl border border-white/15">
              <Compass className="w-6 h-6 text-teal-300" />
              <span className="font-extrabold tracking-tight text-lg">TripFlow CMS</span>
            </div>
            <h1 className="text-2xl font-extrabold mt-6 leading-snug">
              Hệ Thống Quản Trị Du Lịch, Ẩm Thực & Lộ Trình Thông Minh
            </h1>
            <p className="text-sm text-teal-100/90 mt-3 leading-relaxed">
              Quản lý tập trung dữ liệu Tỉnh/thành, Địa điểm du lịch, Đặc sản, Nhà hàng dọc lộ trình
              (Corridor Search), Lịch trình mẫu, Kiểm duyệt báo sai thông tin và Nhật ký Audit Logs.
            </p>
          </div>

          <div className="mt-8 pt-6 border-t border-white/15 text-xs text-teal-100/80 space-y-2">
            <div className="flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-teal-300 shrink-0" />
              <span>Phân quyền RBAC 5 cấp độ & giới hạn theo Tỉnh/Thành</span>
            </div>
            <div className="flex items-center gap-2">
              <KeyRound className="w-4 h-4 text-teal-300 shrink-0" />
              <span>Bảo vệ Server API Key & Giám sát ngân sách Bản đồ</span>
            </div>
          </div>
        </div>

        {/* Right Form & Demo Roles */}
        <div className="lg:col-span-7 p-8">
          <h2 className="text-xl font-extrabold text-slate-900">Đăng nhập Quản trị viên</h2>
          <p className="text-xs text-slate-500 mt-1">
            Nhập thông tin tài khoản hoặc bấm chọn nhanh 1 trong 4 vai trò RBAC bên dưới để kiểm thử:
          </p>

          {error && (
            <div className="mt-4 p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-medium">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="mt-5 space-y-4">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Email Quản trị
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 text-sm border border-slate-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-500"
                  placeholder="admin@tripflow.vn"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Mật khẩu</label>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 text-sm border border-slate-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-500"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-2.5 px-4 bg-teal-600 hover:bg-teal-700 text-white font-bold text-sm rounded-xl shadow-md transition-colors disabled:opacity-50"
            >
              {loading ? "Đang xác thực..." : "Đăng nhập vào TripFlow Admin"}
            </button>
          </form>

          {/* Quick Demo Role Buttons */}
          <div className="mt-6 pt-5 border-t border-slate-200">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3">
              Tài khoản mẫu theo vai trò RBAC (1-Click Login)
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
              {DEMO_ADMIN_ACCOUNTS.map((acc) => (
                <button
                  key={acc.email}
                  type="button"
                  onClick={() => handleQuickFill(acc)}
                  className="text-left p-3 rounded-xl border border-slate-200 hover:border-teal-500 hover:bg-teal-50/40 transition-all group"
                >
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-bold text-slate-800 group-hover:text-teal-700">
                      {acc.label}
                    </span>
                  </div>
                  <p className="text-[11px] text-slate-500 mt-0.5 truncate">{acc.email}</p>
                  <p className="text-[11px] text-slate-400 mt-1 line-clamp-1">{acc.desc}</p>
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
