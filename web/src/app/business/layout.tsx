import { Suspense } from "react";
import { redirect } from "next/navigation";
import { Sidebar } from "@/components/sidebar";
import { getStaffShops, getCurrentShop } from "@/lib/auth";

export default function BusinessLayout({ children }: LayoutProps<"/business">) {
  return (
    <Suspense fallback={<div className="min-h-screen bg-[#F6F5F1]" />}>
      <StaffGate>{children}</StaffGate>
    </Suspense>
  );
}

async function StaffGate({ children }: { children: React.ReactNode }) {
  const shops = await getStaffShops();
  // not staff anywhere then back to personal mode
  if (shops.length === 0) redirect("/");

  const current = await getCurrentShop();

  return (
    <div className="flex min-h-screen bg-[#F6F5F1]">
      <Sidebar shops={shops} currentId={current.id} />
      <main className="flex-1 p-8">{children}</main>
    </div>
  );
}
