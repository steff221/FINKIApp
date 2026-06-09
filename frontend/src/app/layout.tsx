import type { Metadata } from "next";
import "./globals.css";
import NavBar from "@/components/ui/NavBar";
import PageTransition from "@/components/ui/PageTransition";

export const metadata: Metadata = {
  title: "FINKI Scheduler",
  description: "Unified timetable and consultation schedule for FINKI students",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <NavBar />
        <main className="max-w-7xl mx-auto px-6 py-8">
          <PageTransition>{children}</PageTransition>
        </main>
      </body>
    </html>
  );
}
