import { Suspense } from "react";
import { getCurrentShop } from "@/lib/auth";
import { createClient } from "@/lib/supabase/server";
import { ProgramForm } from "@/components/program-form";

export default function RewardsPage() {
  return (
    <Suspense fallback={null}>
      <Rewards />
    </Suspense>
  );
}

async function Rewards() {
  const shop = await getCurrentShop();
  const supabase = await createClient();
  const { data: program } = await supabase
    .from("stamp_programs")
    .select("reward, stamps_needed, max_stamps_per_visit")
    .eq("shop_id", shop.id)
    .maybeSingle();

  return (
    <div className="mx-auto max-w-6xl">
      <h1 className="text-3xl font-bold tracking-tight text-[#1E2B2A]">
        Rewards
      </h1>
      <p className="mt-1 text-sm text-[#6E7772]">
        Your stamp card. Changes show up in the app right away.
      </p>

      {program ? (
        <ProgramForm program={program} canEdit={shop.role !== "staff"} />
      ) : (
        <p className="mt-6 text-sm text-[#6E7772]">
          This shop doesn&apos;t have a stamp card yet.
        </p>
      )}
    </div>
  );
}
