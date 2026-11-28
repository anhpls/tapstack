import { Suspense } from "react";
import { getCurrentShop } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { ShopForm } from "@/components/shop-form";
import { Team } from "@/components/team";

export default function SettingsPage() {
  return (
    <Suspense fallback={null}>
      <Settings />
    </Suspense>
  );
}

async function Settings() {
  const current = await getCurrentShop();
  const supabase = await createClient();
  const { data: shop } = await supabase
    .from("shops")
    .select("name, category, color_hex")
    .eq("id", current.id)
    .single();
  const canManage = current.role !== "staff";
  const [team, invites] = canManage
    ? await Promise.all([
        supabase.rpc("shop_team", { p_shop_id: current.id }),
        supabase
          .from("shop_invites")
          .select("id, email, role")
          .eq("shop_id", current.id)
          .order("created_at"),
      ])
    : [null, null];

  return (
    <div className="mx-auto max-w-6xl">
      <h1 className="text-3xl font-bold tracking-tight text-[#1E2B2A]">
        Settings
      </h1>

      <h2 className="mt-8 text-xs font-bold uppercase tracking-wide text-[#6E7772]">
        Shop
      </h2>
      {shop && <ShopForm shop={shop} canEdit={current.role !== "staff"} />}

      <h2 className="mt-10 text-xs font-bold uppercase tracking-wide text-[#6E7772]">
        Team
      </h2>
      {canManage ? (
        <Team
          members={team?.data ?? []}
          invites={invites?.data ?? []}
          myRole={current.role}
        />
      ) : (
        <p className="mt-4 text-sm text-[#6E7772]">
          Ask an owner to manage the team.
        </p>
      )}
    </div>
  );
}
