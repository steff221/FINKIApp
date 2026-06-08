"use client";

import Link from "next/link";
import Image from "next/image";
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

  return (
    <>
      <nav className="bg-finki-navy sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center gap-4">
          {/* Logo */}
          <Link href="/" className="shrink-0 flex items-center mr-2">
            <Image
              src="/FINKI_logo-removebg-preview.png"
              alt="FINKI"
              width={72}
              height={24}
              className="object-contain"
              priority
            />
          </Link>

          <div className="h-5 w-px bg-white/20" />

          {/* Nav links */}
          <div className="flex items-center gap-1">
            {[
              { href: "/timetable",     label: "Timetable" },
              { href: "/consultations", label: "Consultations" },
              { href: "/schedule",      label: "My Schedule" },
              { href: "/maps",          label: "Maps" },
            ].map(({ href, label }) => {
              const active = pathname.startsWith(href);
              return (
                <Link
                  key={href}
                  href={href}
                  className={`relative px-4 py-2 rounded-lg text-sm font-medium transition-all duration-150 ${
                    active
                      ? "bg-white/15 text-white"
                      : "text-white/65 hover:text-white hover:bg-white/10"
                  }`}
                >
                  {label}
                  {active && (
                    <span className="absolute bottom-0.5 left-4 right-4 h-0.5 bg-blue-300 rounded-full" />
                  )}
                </Link>
              );
            })}
          </div>

          {/* Auth */}
          <div className="ml-auto flex items-center gap-3">
            {auth ? (
              <div className="flex items-center gap-2.5 bg-white/10 rounded-full pl-1 pr-1.5 py-1">
                <span className="w-7 h-7 rounded-full bg-blue-300 text-finki-navy text-xs font-bold flex items-center justify-center shrink-0">
                  {auth.email.slice(0, 2).toUpperCase()}
                </span>
                <span className="text-white/80 text-sm hidden sm:block max-w-[140px] truncate">{auth.email}</span>
                <button
                  onClick={handleLogout}
                  title="Sign out"
                  className="w-7 h-7 rounded-full hover:bg-white/15 flex items-center justify-center text-white/70 hover:text-white transition-colors"
                  aria-label="Sign out"
                >
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                    <polyline points="16 17 21 12 16 7" />
                    <line x1="21" y1="12" x2="9" y2="12" />
                  </svg>
                </button>
              </div>
            ) : (
              <button
                onClick={() => setShowAuth(true)}
                className="bg-white text-finki-navy px-4 py-1.5 rounded-lg text-sm font-semibold hover:bg-blue-50 transition-colors shadow-sm"
              >
                Log in
              </button>
            )}
          </div>
        </div>
      </nav>

      {showAuth && <AuthModal onClose={() => setShowAuth(false)} />}
    </>
  );
}
