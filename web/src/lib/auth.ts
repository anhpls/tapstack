import "server-only";
import { connection } from "next/server";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import type { Database } from "@/lib/database.types"

export type StaffShop = {
  id: string;
  name: string;
  role: Database["public"]["Enums"]["shop_role"]; // from db so stays in sync
};

// who's signed in, and which shops they work at
export async function getStaffShops(): Promise<StaffShop[]> {
  await connection();
  const supabase = await createClient();

  const { data } = await supabase.auth.getClaims();
  const userId = data?.claims?.sub;
  if (!userId) redirect("/login"); // backup in case proxy didn't catch it

  // rls only lets you read your own rows here, so this can't leak other people's shops
  const { data: rows, error } = await supabase
    .from("shop_members")
    .select("role, shops(id, name)")
    .eq("user_id", userId);

  if (error) throw error;

  return (rows ?? []).flatMap((r) =>
    r.shops
      ? [
          {
            id: r.shops.id,
            name: r.shops.name,
            role: r.role as StaffShop["role"],
          },
        ] // db check only allows these 3
      : [],
  );
}
