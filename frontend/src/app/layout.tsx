import type { Metadata } from "next";
import "./globals.css";
import NavBar from "@/components/ui/NavBar";
import PageTransition from "@/components/ui/PageTransition";

export const metadata: Metadata = {
  title: "ФИНКИ Распоред",
  description: "Распоред на часови, консултации и карта на кампусот за студентите на ФИНКИ",
  manifest: "/manifest.json",
  themeColor: "#0d1b40",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="mk">
      <body>
        <NavBar />
        <main className="max-w-7xl mx-auto px-6 py-8">
          <PageTransition>{children}</PageTransition>
        </main>
      </body>
    </html>
  );
}
