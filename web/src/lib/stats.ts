import "server-only";
import { createClient } from "@/lib/supabase/server";

// the 4 numbers on the overview page
export async function getOverviewStats(shopId: string) {
  const supabase = await createClient();
  const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(); // 30 days ago

  // head: true = just count rows, don't send them back
  const count = { count: "exact" as const, head: true };

  // all 4 at once instead of one after another
  const [members, activity, rewards, transfers] = await Promise.all([
    supabase
      .from("memberships")
      .select("id", count)
      .eq("shop_id", shopId)
      .is("hidden_at", null), // skip cards people removed

    // stamps don't have a shop_id, so join through memberships to filter by shop
    supabase.rpc("shop_activity", { p_shop_id: shopId }),

    supabase
      .from("redemptions")
      .select("id, memberships!inner(shop_id)", count)
      .eq("memberships.shop_id", shopId)
      .gte("created_at", since),

    supabase
      .from("transfer_requests")
      .select("id", count)
      .eq("shop_id", shopId)
      .eq("status", "completed"),
  ]);

  const a = activity.data?.[0]; // functions that return a table come back as an array
  const active = a?.active_count ?? 0;
  const repeat = a?.repeat_count ?? 0;

  return {
    members: members.count ?? 0,
    active,
    repeat,
    returnRate: active ? Math.round((repeat / active) * 100) : 0,
    rewards: rewards.count ?? 0,
    transfers: transfers.count ?? 0,
  };
}
