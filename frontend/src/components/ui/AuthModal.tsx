"use client";

import { useState, useEffect, useRef } from "react";
import { login, register } from "@/lib/api";
import { saveAuth } from "@/lib/auth";
import { useFocusTrap } from "@/hooks/useFocusTrap";

interface Props { onClose: () => void; }

function useEscClose(onClose: () => void) {
  useEffect(() => {
    const h = (e: KeyboardEvent) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", h);
    return () => window.removeEventListener("keydown", h);
  }, [onClose]);
}

const inputCls = "w-full bg-gray-50 border border-gray-200 rounded-lg px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-400 transition-all";

export default function AuthModal({ onClose }: Props) {
  const [mode, setMode] = useState<"login" | "register">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPw, setShowPw] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const dialogRef = useRef<HTMLDivElement>(null);

  useEscClose(onClose);
  useFocusTrap(dialogRef);

  function switchMode(next: "login" | "register") {
    setMode(next);
    setError(null);
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = mode === "login"
        ? await login(email, password)
        : await register(email, password);
      saveAuth(res.token, res.userId, res.email);
      window.location.reload();
    } catch (err) {
      const msg = err instanceof Error ? err.message : "";
      if (msg.includes("409")) {
        setError("Ова корисничко ime веќе е регистрирано — обидете се да се најавите.");
      } else if (msg.includes("401") || msg.includes("403")) {
        setError(mode === "login"
          ? "Погрешно корисничко ime или лозинка."
          : "Не може да се создаде сметката.");
      } else {
        setError("Нешто тргна наопаку. Обидете се повторно.");
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/40 backdrop-blur-sm" onClick={onClose} />

      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-label={mode === "login" ? "Најави се" : "Создади сметка"}
        className="relative bg-white rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden"
      >
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100">
          <h2 className="font-bold text-gray-900 text-base">
            {mode === "login" ? "Добредојдовте" : "Создади сметка"}
          </h2>
          <button
            onClick={onClose}
            className="w-7 h-7 rounded-full hover:bg-gray-100 flex items-center justify-center transition-colors"
            aria-label="Затвори"
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <path d="M18 6 6 18M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="p-5">
          {/* Segmented mode toggle */}
          <div className="grid grid-cols-2 gap-1 bg-gray-100 rounded-xl p-1 mb-5">
            {(["login", "register"] as const).map(m => (
              <button
                key={m}
                type="button"
                onClick={() => switchMode(m)}
                className={`py-1.5 rounded-lg text-sm font-semibold transition-all ${
                  mode === m ? "bg-white text-finki-navy shadow-sm" : "text-gray-500 hover:text-gray-700"
                }`}
              >
                {m === "login" ? "Најави се" : "Регистрирај се"}
              </button>
            ))}
          </div>

          <form onSubmit={handleSubmit} className="space-y-3" autoComplete="off">
            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Индекс / Корисничко Ime
              </label>
              <input
                type="text"
                name="finki-username"
                placeholder="пр. 231199"
                value={email}
                onChange={e => setEmail(e.target.value)}
                required
                autoComplete="off"
                data-lpignore="true"
                data-1p-ignore="true"
                className={inputCls}
                autoFocus
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">
                Лозинка
              </label>
              <div className="relative">
                <input
                  type={showPw ? "text" : "password"}
                  name="finki-password"
                  placeholder={mode === "register" ? "Минимум 8 знаци" : "Вашата лозинка"}
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  required
                  minLength={8}
                  autoComplete="new-password"
                  data-lpignore="true"
                  data-1p-ignore="true"
                  className={`${inputCls} pr-10`}
                />
                <button
                  type="button"
                  onClick={() => setShowPw(s => !s)}
                  className="absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
                  aria-label={showPw ? "Скриј лозинка" : "Прикажи лозинка"}
                  tabIndex={-1}
                >
                  {showPw ? (
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M9.88 9.88a3 3 0 1 0 4.24 4.24" />
                      <path d="M10.73 5.08A10.43 10.43 0 0 1 12 5c7 0 10 7 10 7a13.16 13.16 0 0 1-1.67 2.68" />
                      <path d="M6.61 6.61A13.526 13.526 0 0 0 2 12s3 7 10 7a9.74 9.74 0 0 0 5.39-1.61" />
                      <path d="m2 2 20 20" />
                    </svg>
                  ) : (
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z" />
                      <circle cx="12" cy="12" r="3" />
                    </svg>
                  )}
                </button>
              </div>
              {mode === "register" && (
                <p className={`text-[11px] mt-1 ${password.length >= 8 ? "text-emerald-600" : "text-gray-400"}`}>
                  {password.length >= 8 ? "✓ Во ред" : "Мора да има барем 8 знаци"}
                </p>
              )}
            </div>

            {error && (
              <p className="text-xs text-red-600 bg-red-50 rounded-lg px-3 py-2">{error}</p>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-finki-navy text-white py-2.5 rounded-lg font-semibold text-sm hover:bg-finki-mid transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {loading && (
                <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
              )}
              {loading ? "Ве молиме почекајте…" : mode === "login" ? "Најави се" : "Создади сметка"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
