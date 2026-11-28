"use server";

import { revalidatePath } from "next/cache";
import { getCurrentShop } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";

export type ProgramState = { error?: string; saved?: boolean };

export async function saveProgram(
  _prev: ProgramState,
  form: FormData,
): Promise<ProgramState> {
  const shop = await getCurrentShop();
  if (shop.role === "staff")
    return { error: "Only owners and managers can change the card." };

  const reward = String(form.get("reward") ?? "").trim();
  const needed = Number(form.get("stamps_needed"));
  const perVisit = Number(form.get("max_stamps_per_visit"));

  // check here for nice messages, the db checks again anyway
  if (!reward) return { error: "Give the reward a name." };
  if (!Number.isInteger(needed) || needed < 1 || needed > 50)
    return { error: "Stamps needed has to be 1 to 50." };
  if (!Number.isInteger(perVisit) || perVisit < 1 || perVisit > 20)
    return { error: "Stamps per visit has to be 1 to 20." };

  const supabase = await createClient();
  const { data, error } = await supabase
    .from("stamp_programs")
    .update({ reward, stamps_needed: needed, max_stamps_per_visit: perVisit })
    .eq("shop_id", shop.id)
    .select("id"); // ask for the row back so we can tell if it actually saved

  if (error) return { error: error.message };
  // rls blocking an update doesn't error, it just changes 0 rows
  if (!data?.length)
    return { error: "Couldn't save. Do you have access to this shop?" };

  revalidatePath("/business", "layout"); // overview + customers use stamps_needed too
  return { saved: true };
}
