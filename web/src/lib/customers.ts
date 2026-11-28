import "server-only";
import { createClient } from "@/lib/supabase/server";

export type Status =
  | "Reward ready"
  | "New"
  | "Regular"
  | "Slipping away"
  | "Lapsed";

const DAY = 24 * 60 * 60 * 1000;
const daysSince = (iso: string | null) =>
  iso ? Math.floor((Date.now() - new Date(iso).getTime()) / DAY) : Infinity;

// first match wins, so order matters
function statusFor(
  c: { balance: number; joined_at: string | null; last_visit: string | null },
  needed: number,
): Status {
  const away = daysSince(c.last_visit);
  if (c.balance >= needed) return "Reward ready";
  if (daysSince(c.joined_at) <= 14) return "New";
  if (away > 45) return "Lapsed";
  if (away > 30) return "Slipping away";
  return "Regular";
}

export async function getCustomers(shopId: string) {
  const supabase = await createClient();

  const [{ data: rows, error }, { data: program }] = await Promise.all([
    supabase.rpc("shop_customers", { p_shop_id: shopId }),
    supabase
      .from("stamp_programs")
      .select("stamps_needed")
      .eq("shop_id", shopId)
      .maybeSingle(),
  ]);
  if (error) throw error;

  const needed = program?.stamps_needed ?? 10;

  return {
    needed,
    customers: (rows ?? []).map((c) => ({
      ...c,
      status: statusFor(c, needed),
      lastLabel: lastVisitLabel(c.last_visit),
    })),
  };
}

// "today", "yesterday", "12 days ago"
function lastVisitLabel(iso: string | null) {
  const d = daysSince(iso);
  if (d === Infinity) return "No visits yet";
  if (d === 0) return "Today";
  if (d === 1) return "Yesterday";
  return `${d} days ago`;
}
