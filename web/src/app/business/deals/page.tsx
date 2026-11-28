import { Suspense } from "react";
import { getCurrentShop } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { DealForm } from "@/components/deal-form";
import { endDeal, deleteDeal } from "./actions";

// todo: give shops their own timezone column instead of hardcoding
const SHOP_TZ = "America/Los_Angeles";
const fmt = (iso: string) =>
  new Date(iso).toLocaleString("en-US", {
    month: "short",
    day: "numeric",
    hour: "numeric",
    minute: "2-digit",
    timeZone: SHOP_TZ,
  });

export default function DealsPage() {
  return (
    <Suspense fallback={null}>
      <Deals />
    </Suspense>
  );
}

async function Deals() {
  const shop = await getCurrentShop();
  const canEdit = shop.role !== "staff";
  const supabase = await createClient();
  const { data: deals } = await supabase
    .from("stamp_promos")
    .select("id, name, multiplier, starts_at, ends_at")
    .eq("shop_id", shop.id)
    .order("starts_at", { ascending: false });

  const now = Date.now();
  const t = (iso: string) => new Date(iso).getTime();
  const live = (deals ?? []).filter(
    (d) => t(d.starts_at) <= now && t(d.ends_at) > now,
  );
  const upcoming = (deals ?? []).filter((d) => t(d.starts_at) > now);
  const past = (deals ?? []).filter((d) => t(d.ends_at) <= now).slice(0, 10); // just the recent ones

  type Deal = NonNullable<typeof deals>[number];
  const row = (d: Deal, button?: React.ReactNode) => (
    <li
      key={d.id}
      className="flex items-center justify-between gap-4 border-t border-[#EFEDE7] px-6 py-3.5 first:border-t-0"
    >
      <div>
        <p className="font-semibold">
          {d.name} <span className="text-[#9A4A38]">{d.multiplier}x</span>
        </p>
        <p className="text-xs text-[#6E7772]">
          {fmt(d.starts_at)} → {fmt(d.ends_at)}
        </p>
      </div>
      {canEdit && button}
    </li>
  );

  const section = (
    title: string,
    list: Deal[],
    button?: (d: Deal) => React.ReactNode,
  ) => (
    <section className="mt-8">
      <h2 className="text-xs font-bold uppercase tracking-wide text-[#6E7772]">
        {title}
      </h2>
      {list.length ? (
        <ul className="mt-3 rounded-2xl border border-[#E6E3DC] bg-white">
          {list.map((d) => row(d, button?.(d)))}
        </ul>
      ) : (
        <p className="mt-3 text-sm text-[#6E7772]">None right now.</p>
      )}
    </section>
  );

  // bind() bakes the deal id into the server action
  const btn =
    "rounded-full border border-[#E6E3DC] px-3.5 py-1.5 text-xs font-bold hover:border-[#1E2B2A]";

  return (
    <div className="mx-auto max-w-6xl">
      <h1 className="text-3xl font-bold tracking-tight text-[#1E2B2A]">
        Deals
      </h1>
      <p className="mt-1 text-sm text-[#6E7772]">
        Extra stamps for a set time. The app applies them at checkout.
      </p>

      {canEdit && <DealForm />}

      {section("Live", live, (d) => (
        <form action={endDeal.bind(null, d.id)}>
          <button className={btn}>End now</button>
        </form>
      ))}
      {section("Upcoming", upcoming, (d) => (
        <form action={deleteDeal.bind(null, d.id)}>
          <button className={btn}>Delete</button>
        </form>
      ))}
      {section("Past", past)}
    </div>
  );
}
