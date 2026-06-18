"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { Menu, X } from "lucide-react";
import { MOBILE_PRIMARY_NAV, NAV_SECTIONS } from "@/lib/navigation";
import { cn } from "@/lib/utils";

export function MobileHeader() {
  const [open, setOpen] = useState(false);

  return (
    <>
      <header className="flex items-center justify-between border-b border-neutral-200 bg-white p-4 md:hidden">
        <Link href="/" className="text-lg font-bold text-neutral-900">
          Recomp Tracker
        </Link>
        <button
          aria-label="Open menu"
          onClick={() => setOpen(true)}
          className="rounded-md p-2 hover:bg-neutral-100"
        >
          <Menu className="h-5 w-5" />
        </button>
      </header>

      {open && (
        <div className="fixed inset-0 z-50 flex flex-col bg-white md:hidden">
          <div className="flex items-center justify-between border-b border-neutral-200 p-4">
            <span className="text-lg font-bold">Menu</span>
            <button
              aria-label="Close menu"
              onClick={() => setOpen(false)}
              className="rounded-md p-2 hover:bg-neutral-100"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
          <nav className="flex flex-1 flex-col gap-6 overflow-y-auto p-4">
            {NAV_SECTIONS.map((section) => (
              <div key={section.title} className="flex flex-col gap-1">
                <span className="px-2 text-xs font-semibold uppercase tracking-wide text-neutral-400">
                  {section.title}
                </span>
                {section.items.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setOpen(false)}
                    className="rounded-md px-2 py-2.5 text-base font-medium text-neutral-700 hover:bg-neutral-100"
                  >
                    {item.label}
                  </Link>
                ))}
              </div>
            ))}
          </nav>
        </div>
      )}
    </>
  );
}

export function BottomTabBar() {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);

  return (
    <>
      <nav className="fixed inset-x-0 bottom-0 z-40 flex border-t border-neutral-200 bg-white pb-[env(safe-area-inset-bottom)] md:hidden">
        {MOBILE_PRIMARY_NAV.map((item) => {
          const active = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex flex-1 flex-col items-center gap-0.5 py-2.5 text-[11px] font-medium text-neutral-500",
                active && "text-neutral-900"
              )}
            >
              {item.label}
            </Link>
          );
        })}
        <button
          onClick={() => setOpen(true)}
          className="flex flex-1 flex-col items-center gap-0.5 py-2.5 text-[11px] font-medium text-neutral-500"
        >
          More
        </button>
      </nav>

      {open && (
        <div className="fixed inset-0 z-50 flex flex-col justify-end bg-black/30 md:hidden" onClick={() => setOpen(false)}>
          <div
            className="max-h-[75vh] overflow-y-auto rounded-t-2xl bg-white p-4 pb-8"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="mb-2 flex items-center justify-between">
              <span className="text-base font-bold">More</span>
              <button onClick={() => setOpen(false)} className="rounded-md p-2 hover:bg-neutral-100">
                <X className="h-5 w-5" />
              </button>
            </div>
            {NAV_SECTIONS.map((section) => (
              <div key={section.title} className="mb-4 flex flex-col gap-1">
                <span className="px-2 text-xs font-semibold uppercase tracking-wide text-neutral-400">
                  {section.title}
                </span>
                {section.items.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setOpen(false)}
                    className="rounded-md px-2 py-2.5 text-base font-medium text-neutral-700 hover:bg-neutral-100"
                  >
                    {item.label}
                  </Link>
                ))}
              </div>
            ))}
          </div>
        </div>
      )}
    </>
  );
}
