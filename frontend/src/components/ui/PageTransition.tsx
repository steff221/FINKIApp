"use client";

import { usePathname } from "next/navigation";

/** Replays a subtle fade-in whenever the route changes. */
export default function PageTransition({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  return (
    <div key={pathname} className="animate-page">
      {children}
    </div>
  );
}
