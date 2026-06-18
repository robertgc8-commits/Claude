import type { Metadata } from "next";
import "./globals.css";
import { Sidebar } from "@/components/nav/Sidebar";
import { MobileHeader, BottomTabBar } from "@/components/nav/MobileNav";

export const metadata: Metadata = {
  title: "Recomp Tracker",
  description: "Personal body-composition, Zepbound, and strength-training tracker",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full antialiased">
      <body className="flex min-h-full flex-col bg-neutral-50 text-neutral-900 md:flex-row">
        <Sidebar />
        <div className="flex min-h-screen flex-1 flex-col">
          <MobileHeader />
          <main className="flex-1 px-4 pb-24 pt-4 md:px-8 md:py-8 md:pb-8">{children}</main>
        </div>
        <BottomTabBar />
      </body>
    </html>
  );
}
