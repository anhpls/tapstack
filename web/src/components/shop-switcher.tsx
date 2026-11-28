"use client";

import { useTransition } from "react";
import { switchShop } from "@/app/business/actions";
import type { StaffShop } from "@/lib/auth";
import { ChevronDown } from "lucide-react";

export function ShopSwitcher({
  shops,
  currentId,
}: {
  shops: StaffShop[];
  currentId: string;
}) {
  const [pending, startTransition] = useTransition();

  // only one shop then just show its name
  if (shops.length < 2) {
    return <p className="px-3 text-sm font-medium">{shops[0]?.name}</p>;
  }

  return (
  // relative so the arrow can sit on top of the select
  <div className="relative">
    <select
      value={currentId}
      disabled={pending}
      onChange={(e) => startTransition(() => switchShop(e.target.value))}
      className="w-full appearance-none rounded-xl border border-neutral-200 bg-white py-2 pl-3 pr-9 text-sm"
    >
      {shops.map((s) => (
        <option key={s.id} value={s.id}>
          {s.name}
        </option>
      ))}
    </select>
    {/* our own arrow, pointer-events-none so clicks still hit the select */}
    <ChevronDown className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-neutral-400" />
  </div>
);
}
