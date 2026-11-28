"use server";

import { cookies } from "next/headers";
import { getStaffShops } from "@/lib/auth";

// remembers which shop you picked
export async function switchShop(shopId: string) {
  const shops = await getStaffShops();
  if (!shops.some((s) => s.id === shopId)) return; // not your shop, ignore it

  (await cookies()).set("ts_shop", shopId, {
    path: "/",
    httpOnly: true, // js in the browser can't touch it
    sameSite: "lax",
    maxAge: 60 * 60 * 24 * 365, // remember for a year
  });
}
