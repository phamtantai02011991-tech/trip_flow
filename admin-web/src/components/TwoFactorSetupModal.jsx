import React, { useEffect, useState } from "react";
import { KeyRound, ShieldCheck, X } from "lucide-react";
import { adminApi } from "../services/api/client";

export default function TwoFactorSetupModal({ open, onClose }) {
  const [secret, setSecret] = useState("");
  const [otpauthUrl, setOtpauthUrl] = useState("");
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);

  useEffect(() => {
    if (!open) return;
    let cancelled = false;
    setError("");
    setDone(false);
    setCode("");
    adminApi
      .setup2fa()
      .then((data) => {
        if (cancelled) return;
        setSecret(data.secret || "");
        setOtpauthUrl(data.otpauth_url || "");
      })
      .catch((err) => {
        if (!cancelled) setError(err.message || "Không tạo được secret 2FA.");
      });
    return () => {
      cancelled = true;
    };
  }, [open]);

  if (!open) return null;

  const handleEnable = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await adminApi.enable2fa(code.trim());
      setDone(true);
      setTimeout(() => window.location.reload(), 900);
    } catch (err) {
      setError(err.message || "Mã 2FA không đúng.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/70 p-4">
      <div className="w-full max-w-lg rounded-2xl bg-white shadow-2xl p-6">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-teal-50 flex items-center justify-center">
              <ShieldCheck className="w-5 h-5 text-teal-600" />
            </div>
            <div>
              <h3 className="text-base font-extrabold text-slate-900">
                Thiết lập xác thực 2 lớp (2FA)
              </h3>
              <p className="text-xs text-slate-500">
                Dùng Google Authenticator / Authy / 1Password
              </p>
            </div>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600">
            <X className="w-5 h-5" />
          </button>
        </div>

        {done ? (
          <div className="mt-6 rounded-xl bg-emerald-50 border border-emerald-200 p-4 text-sm text-emerald-800 font-semibold">
            Đã bật 2FA. Đang tải lại trang...
          </div>
        ) : (
          <>
            {error && (
              <div className="mt-4 rounded-xl bg-rose-50 border border-rose-200 p-3 text-xs text-rose-700">
                {error}
              </div>
            )}

            <ol className="mt-4 space-y-3 text-sm text-slate-700">
              <li>
                <span className="font-bold">1.</span> Mở ứng dụng xác thực → chọn “Thêm tài khoản” → “Nhập khoá thủ công”.
              </li>
              <li>
                <span className="font-bold">2.</span> Nhập tên <b>TripFlow</b> và khoá bên dưới:
                <div className="mt-2 flex items-center gap-2">
                  <code className="flex-1 break-all rounded-lg bg-slate-100 px-3 py-2 text-xs font-mono text-slate-800">
                    {secret || "Đang tạo..."}
                  </code>
                  <button
                    type="button"
                    onClick={() => navigator.clipboard?.writeText(secret)}
                    className="rounded-lg border border-slate-200 px-3 py-2 text-xs font-bold text-slate-600 hover:bg-slate-50"
                  >
                    Sao chép
                  </button>
                </div>
                {otpauthUrl && (
                  <p className="mt-1 text-[11px] text-slate-400 break-all">
                    Hoặc mở liên kết: {otpauthUrl}
                  </p>
                )}
              </li>
              <li>
                <span className="font-bold">3.</span> Nhập mã 6 số đang hiển thị để xác nhận.
              </li>
            </ol>

            <form onSubmit={handleEnable} className="mt-4 flex gap-2">
              <div className="relative flex-1">
                <KeyRound className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  value={code}
                  onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
                  inputMode="numeric"
                  placeholder="123456"
                  className="w-full pl-10 pr-3 py-2.5 text-sm font-mono tracking-[0.35em] border border-slate-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-teal-500"
                />
              </div>
              <button
                type="submit"
                disabled={loading || code.length !== 6}
                className="rounded-xl bg-teal-600 px-4 py-2.5 text-sm font-bold text-white hover:bg-teal-700 disabled:opacity-50"
              >
                {loading ? "Đang bật..." : "Bật 2FA"}
              </button>
            </form>
          </>
        )}
      </div>
    </div>
  );
}
