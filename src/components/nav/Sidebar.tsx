"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { NAV_SECTIONS } from "@/lib/navigation";
import { cn } from "@/lib/utils";

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="hidden md:flex md:w-60 md:flex-col md:gap-6 md:border-r md:border-neutral-200 md:bg-white md:p-4 md:pt-6">
      <Link href="/" className="px-2 text-lg font-bold text-neutral-900">
        Recomp Tracker
      </Link>
      <nav className="flex flex-col gap-5">
        {NAV_SECTIONS.map((section) => (
          <div key={section.title} className="flex flex-col gap-1">
            <span className="px-2 text-xs font-semibold uppercase tracking-wide text-neutral-400">
              {section.title}
            </span>
            {section.items.map((item) => {
              const active = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "rounded-md px-2 py-1.5 text-sm font-medium text-neutral-600 hover:bg-neutral-100",
                    active && "bg-neutral-900 text-white hover:bg-neutral-900"
                  )}
                >
                  {item.label}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>
    </aside>
  );
}
