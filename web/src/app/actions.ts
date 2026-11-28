"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";

export async function signOut() {
  const supabase = await createClient();
  await supabase.auth.signOut(); // clears the session cookies

  // forget the picked shop too, next person on this browser starts fresh
  (await cookies()).delete("ts_shop");

  redirect("/login");
}
