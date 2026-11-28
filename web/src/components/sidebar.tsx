"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { LayoutDashboard, Tag, Stamp, Users, Settings } from "lucide-react";
import Image from "next/image";
import type { StaffShop } from "@/lib/auth";
import { ShopSwitcher } from "./shop-switcher";
// nav bar
const nav = [
  { href: "/business", label: "Overview", icon: LayoutDashboard },
  { href: "/business/customers", label: "Customers", icon: Users },
  { href: "/business/rewards", label: "Rewards", icon: Stamp },
  { href: "/business/deals", label: "Deals", icon: Tag },
  { href: "/business/settings", label: "Settings", icon: Settings },
];

export function Sidebar({
  shops,
  currentId,
}: {
  shops: StaffShop[];
  currentId: string;
}) {
  const pathname = usePathname();

  return (
    <aside className="hidden w-60 shrink-0 border-r border-neutral-200 bg-white px-4 py-6 md:block">
      <Link href="/business" className="mb-8 block px-2">
        <Image
          src="/brand/tapstack-wordmark.svg"
          alt="Tapstack"
          width={130}
          height={36}
          priority
        />
      </Link>

      {/* which shop you're managing */}
      <div className="mb-6">
        <ShopSwitcher shops={shops} currentId={currentId} />
      </div>

      <nav className="space-y-1">
        {nav.map(({ href, label, icon: Icon }) => {
          const active = pathname === href;
          return (
            <Link
              key={href}
              href={href}
              className={`flex items-center gap-3 rounded-xl px-3 py-2 text-sm font-medium transition ${
                active
                  ? "bg-neutral-900 text-white"
                  : "text-neutral-600 hover:bg-neutral-100"
              }`}
            >
              <Icon className="h-4 w-4" />
              {label}
            </Link>
          );
        })}
      </nav>
      {/* hop back to your own cards */}
      <Link
        href="/"
        className="mt-8 block rounded-xl px-3 py-2 text-sm font-semibold text-[#4E5A55] hover:bg-[#ECEFEA]"
      >
        Switch to personal
      </Link>
    </aside>
  );
}
