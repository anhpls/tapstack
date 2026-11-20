"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LayoutDashboard, Tag, Stamp, Users, Settings } from "lucide-react";

// nav bar
const nav = [
  { href: "/", label: "Overview", icon: LayoutDashboard },
  { href: "/deals", label: "Deals", icon: Tag },
  { href: "/rewards", label: "Rewards", icon: Stamp },
  { href: "/customers", label: "Customers", icon: Users },
  { href: "/settings", label: "Settings", icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="hidden w-60 shrink-0 border-r border-neutral-200 bg-white px-4 py-6 md:block">
      <div className="mb-8 px-2 text-xl tracking-tight">
        <span className="font-bold">tap</span>
        <span className="font-normal text-neutral-400">stack</span>
      </div>
      <nav className="space-y-1">
        {nav.map(({ href, label, icon: Icon }) => {
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              className={`flex items-center gap-3 rounded-xl px-3 py-2 text-sm font-medium transition ${
                active ? "bg-neutral-900 text-white" : "text-neutral-600 hover:bg-neutral-100"
              }`}
            >
              <Icon className="h-4 w-4" />
              {label}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
