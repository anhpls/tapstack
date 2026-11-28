import { Suspense } from "react";
import { getCurrentShop } from "@/lib/auth";
import { getOverviewStats } from "@/lib/stats";

export default function OverviewPage() {
  return (
    <Suspense fallback={null}>
      <Overview />
    </Suspense>
  );
}

async function Overview() {
  const shop = await getCurrentShop();
  const s = await getOverviewStats(shop.id);

  const cards = [
    { label: "Members", value: s.members, note: "Cards in wallets" },
    {
      label: "Came back",
      value: `${s.returnRate}%`,
      note: `${s.repeat} of ${s.active} this month`,
    },
    { label: "Rewards redeemed", value: s.rewards, note: "Last 30 days" },
    { label: "Paper cards moved", value: s.transfers, note: "Now digital" },
  ];

  return (
    <div className="mx-auto max-w-6xl">
      <h1 className="text-2xl font-semibold tracking-tight">{shop.name}</h1>
      <p className="mt-1 text-sm text-neutral-500">Your shop at a glance</p>

      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {cards.map((c) => (
          <div
            key={c.label}
            className="rounded-2xl border border-neutral-200 bg-white p-5"
          >
            <p className="text-sm text-neutral-500">{c.label}</p>
            <p className="mt-2 text-3xl font-semibold tracking-tight">
              {c.value}
            </p>
            <p className="mt-1 text-xs text-neutral-500">{c.note}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
