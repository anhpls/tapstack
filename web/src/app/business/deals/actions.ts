"use server";

import { revalidatePath } from "next/cache";
import { getCurrentShop } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";

export type DealState = { error?: string; saved?: boolean };

export async function addDeal(_prev: DealState, form: FormData): Promise<DealState> {
  const shop = await getCurrentShop();
  if (shop.role === "staff") return { error: "Only owners and managers can add deals." };

  const name = String(form.get("name") ?? "").trim();
  const multiplier = Number(form.get("multiplier"));
  const startsAt = String(form.get("starts_at") ?? "");
  const endsAt = String(form.get("ends_at") ?? "");

  if (!name) return { error: "Give the deal a name." };
  if (![2, 3, 4, 5].includes(multiplier)) return { error: "Pick 2x to 5x." };
  if (!startsAt || !endsAt) return { error: "Pick a start and an end." };
  if (new Date(endsAt) <= new Date(startsAt)) return { error: "The end has to be after the start." };
  if (new Date(endsAt) <= new Date()) return { error: "That deal would already be over." };

  const supabase = await createClient();
  // unlike update, a blocked insert DOES throw an rls error, so no row check needed
  const { error } = await supabase
    .from("stamp_promos")
    .insert({ shop_id: shop.id, name, multiplier, starts_at: startsAt, ends_at: endsAt });

  if (error) return { error: error.message };
  revalidatePath("/business/deals");
  return { saved: true };
}

// stop a live deal right now
export async function endDeal(id: string) {
  const shop = await getCurrentShop();
  const supabase = await createClient();
  const now = new Date().toISOString();
  await supabase.from("stamp_promos").update({ ends_at: now })
    .eq("id", id).eq("shop_id", shop.id)
    .lte("starts_at", now); // only if it already started
  revalidatePath("/business/deals");
}

// cancel one that hasn't started yet
export async function deleteDeal(id: string) {
  const shop = await getCurrentShop();
  const supabase = await createClient();
  await supabase.from("stamp_promos").delete()
    .eq("id", id).eq("shop_id", shop.id)
    .gt("starts_at", new Date().toISOString()); // past deals stay as history
  revalidatePath("/business/deals");
}
