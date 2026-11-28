import { Suspense } from "react";
import Link from "next/link";
import Image from "next/image";
import { getStaffShops } from "@/lib/auth";
import { signOut } from "./actions";

export default function PersonalHome() {
  return (
    <main className="min-h-screen bg-[#F6F5F1] px-6 py-8">
      <header className="mx-auto flex max-w-5xl items-center justify-between">
        <Image
          src="/brand/tapstack-wordmark.svg"
          alt="Tapstack"
          width={130}
          height={36}
          priority
        />
        <div className="flex items-center gap-3">
          <Suspense fallback={null}>
            <BusinessSwitch />
          </Suspense>
          {/* everyone can sign out, not just staff */}
          <form action={signOut}>
            <button className="rounded-full px-4 py-2.5 text-sm font-semibold text-[#6E7772] hover:bg-[#ECEFEA]">
              Sign out
            </button>
          </form>
        </div>
      </header>

      <section className="mx-auto mt-16 max-w-5xl">
        <h1 className="text-3xl font-bold text-[#1E2B2A]">Your cards</h1>
        <p className="mt-2 text-[#6E7772]">
          Coming soon: your stack, stamps and rewards, right in the browser.
        </p>
      </section>
    </main>
  );
}

// only staff see the switch
async function BusinessSwitch() {
  const shops = await getStaffShops();
  if (shops.length === 0) return null;
  return (
    <Link
      href="/business"
      className="rounded-full bg-[#1E2B2A] px-5 py-2.5 text-sm font-bold text-white"
    >
      Switch to business
    </Link>
  );
}
