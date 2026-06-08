"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import AuthModal from "@/components/ui/AuthModal";
import { getAuth, clearAuth } from "@/lib/auth";

export default function NavBar() {
  const pathname = usePathname();
  const [showAuth, setShowAuth] = useState(false);
  const auth = typeof window !== "undefined" ? getAuth() : null;

  function handleLogout() {
    clearAuth();
    window.location.reload();
  }

  const navLink = (href: string, label: string) => (
    <Link
      href={href}
      className={`px-4 py-2 rounded font-medium transition-colors ${
        pathname.startsWith(href)
          ? "bg-white text-finki-blue"
          : "text-white hover:bg-finki-light"
      }`}
    >
      {label}
    </Link>
  );

  return (
    <nav className="bg-finki-blue shadow-md">
      <div className="max-w-7xl mx-auto px-4 h-14 flex items-center gap-2">
        <span className="text-white font-bold text-lg mr-4">FINKI Scheduler</span>
        {navLink("/timetable", "Timetable")}
        {navLink("/consultations", "Consultations")}
        <div className="ml-auto">
          {auth ? (
            <div className="flex items-center gap-3">
              <span className="text-white text-sm">{auth.email}</span>
              <button
                onClick={handleLogout}
                className="text-white text-sm underline hover:no-underline"
              >
                Log out
              </button>
            </div>
          ) : (
            <button
              onClick={() => setShowAuth(true)}
              className="bg-white text-finki-blue px-3 py-1 rounded font-medium text-sm hover:bg-gray-100"
            >
              Log in
            </button>
          )}
        </div>
      </div>
      {showAuth && <AuthModal onClose={() => setShowAuth(false)} />}
    </nav>
  );
}
