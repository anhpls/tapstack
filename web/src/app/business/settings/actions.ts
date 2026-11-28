"use server";

import { revalidatePath } from "next/cache";
import { getCurrentShop } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import type { StaffShop } from "@/lib/auth";

export type ShopState = { error?: string; saved?: boolean };
export type TeamState = { error?: string; saved?: boolean };

const categories = ["cafe", "boba", "restaurant", "bakery"] as const;
const roles = ["owner", "manager", "staff"] as const;

export async function inviteMember(
  _prev: TeamState,
  form: FormData,
): Promise<TeamState> {
  const shop = await getCurrentShop();
  const email = String(form.get("email") ?? "");
  const role = String(form.get("role") ?? "staff") as StaffShop["role"];
  if (!roles.includes(role)) return { error: "Pick a role." };

  const supabase = await createClient();
  // the db function does the real permission checks and gives readable errors
  const { error } = await supabase.rpc("invite_member", {
    p_shop_id: shop.id,
    p_email: email,
    p_role: role,
  });
  if (error) return { error: error.message };

  revalidatePath("/business/settings");
  return { saved: true };
}

// these return an error message, or null if it worked
export async function changeRole(userId: string, role: StaffShop["role"]) {
  const shop = await getCurrentShop();
  const supabase = await createClient();
  const { error } = await supabase.rpc("set_member_role", {
    p_shop_id: shop.id,
    p_user_id: userId,
    p_role: role,
  });
  revalidatePath("/business/settings");
  return error?.message ?? null;
}

export async function removeMember(userId: string) {
  const shop = await getCurrentShop();
  const supabase = await createClient();
  const { error } = await supabase.rpc("remove_member", {
    p_shop_id: shop.id,
    p_user_id: userId,
  });
  revalidatePath("/business/settings");
  return error?.message ?? null;
}

export async function cancelInvite(id: string) {
  const shop = await getCurrentShop();
  const supabase = await createClient();
  await supabase
    .from("shop_invites")
    .delete()
    .eq("id", id)
    .eq("shop_id", shop.id);
  revalidatePath("/business/settings");
}

export async function saveShop(
  _prev: ShopState,
  form: FormData,
): Promise<ShopState> {
  const shop = await getCurrentShop();
  if (shop.role === "staff")
    return { error: "Only owners and managers can edit the shop." };

  const name = String(form.get("name") ?? "").trim();
  const category = String(form.get("category") ?? "");
  const color = String(form.get("color_hex") ?? "");

  if (!name || name.length > 60)
    return { error: "Name has to be 1 to 60 characters." };
  if (!categories.includes(category as (typeof categories)[number]))
    return { error: "Pick a category." };
  if (!/^#[0-9A-Fa-f]{6}$/.test(color))
    return { error: "That color doesn't look right." };

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("shops")
    .update({ name, category, color_hex: color })
    .eq("id", shop.id)
    .select("id"); // same trick as rewards: blocked updates change 0 rows quietly

  if (error) return { error: error.message };
  if (!data?.length)
    return { error: "Couldn't save. Do you have access to this shop?" };

  revalidatePath("/business", "layout"); // the name shows in the sidebar + overview
  return { saved: true };
}
