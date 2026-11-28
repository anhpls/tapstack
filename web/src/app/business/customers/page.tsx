import { Suspense } from "react";
import { getCurrentShop } from "@/lib/auth";
import { getCustomers, type Status } from "@/lib/customers";
import { CustomerSearch } from "@/components/customer-search";
import Link from "next/link";

// url key -> which status it shows (null = everyone)
const filters: { key: string; label: string; status: Status | null }[] = [
  { key: "all", label: "All", status: null },
  { key: "regulars", label: "Regulars", status: "Regular" },
  { key: "new", label: "New", status: "New" },
  { key: "reward-ready", label: "Reward ready", status: "Reward ready" },
  { key: "slipping", label: "Slipping away", status: "Slipping away" },
];

// muted chip colors from the canvas
const chip: Record<Status, string> = {
  "Reward ready": "bg-[#F5E1DA] text-[#9A4A38]",
  New: "bg-[#E4EEE7] text-[#3F7A58]",
  Regular: "bg-[#E3EAF0] text-[#3D5568]",
  "Slipping away": "bg-[#F3E9D8] text-[#8A6232]",
  Lapsed: "bg-[#EEEDE8] text-[#6E7772]",
};

export default function CustomersPage({
  searchParams,
}: PageProps<"/business/customers">) {
  return (
    <Suspense fallback={null}>
      <Customers searchParams={searchParams} />
    </Suspense>
  );
}

async function Customers({
  searchParams,
}: {
  searchParams: PageProps<"/business/customers">["searchParams"];
}) {
  const shop = await getCurrentShop();
  const { needed, customers } = await getCustomers(shop.id);

  const sp = await searchParams;
  const key = typeof sp.status === "string" ? sp.status : "all"; // could be an array, so check
  const q = typeof sp.q === "string" ? sp.q.trim().toLowerCase() : "";

  const active = filters.find((f) => f.key === key) ?? filters[0];
  const shown = customers.filter(
    (c) =>
      (!active.status || c.status === active.status) &&
      (!q || c.member_number.toLowerCase().includes(q)),
  );

  // keep the search when switching filters
  const hrefFor = (k: string) => {
    const p = new URLSearchParams();
    if (k !== "all") p.set("status", k);
    if (q) p.set("q", q);
    return `/business/customers${p.size ? `?${p}` : ""}`;
  };

  return (
    <div className="mx-auto max-w-6xl">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-sm font-semibold text-[#6E7772]">
            {customers.length} members
          </p>
          <h1 className="text-3xl font-bold tracking-tight text-[#1E2B2A]">
            Customers
          </h1>
        </div>
        <CustomerSearch />
      </div>

      {/* filter chips, each one is just a link */}
      <div className="mt-5 flex flex-wrap gap-2">
        {filters.map((f) => {
          const on = f.key === active.key;
          const count = f.status
            ? customers.filter((c) => c.status === f.status).length
            : customers.length;
          return (
            <Link
              key={f.key}
              href={hrefFor(f.key)}
              scroll={false}
              className={`flex h-9 items-center gap-2 rounded-full border px-3.5 text-sm font-bold ${
                on
                  ? "border-[#1E2B2A] bg-[#1E2B2A] text-white"
                  : "border-[#E6E3DC] bg-white text-[#1E2B2A] hover:border-[#1E2B2A]"
              }`}
            >
              {f.label}
              <span
                className={`rounded-full px-2 py-0.5 text-xs ${on ? "bg-[#46574F] text-white" : "bg-[#EEF1EE] text-[#4E5A55]"}`}
              >
                {count}
              </span>
            </Link>
          );
        })}
      </div>

      <div className="mt-6 overflow-x-auto rounded-2xl border border-[#E6E3DC] bg-white">
        <table className="w-full min-w-190 text-sm">
          <thead>
            <tr className="text-left text-xs uppercase tracking-wide text-[#6E7772]">
              <th className="px-6 py-4 font-bold">Member</th>
              <th className="px-3 py-4 font-bold">Status</th>
              <th className="px-3 py-4 text-right font-bold">Visits</th>
              <th className="px-3 py-4 font-bold">Last visit</th>
              <th className="px-3 py-4 font-bold">Card</th>
              <th className="px-6 py-4 text-right font-bold">Rewards</th>
            </tr>
          </thead>
          <tbody>
            {shown.map((c) => {
              const pct = Math.min(100, (c.balance / needed) * 100); // cap the bar at full
              return (
                <tr
                  key={c.membership_id}
                  className="border-t border-[#EFEDE7] hover:bg-[#F9F8F5]"
                >
                  <td className="px-6 py-3.5">
                    <p className="font-mono font-semibold">{c.member_number}</p>
                    <p className="text-xs text-[#6E7772]">
                      Joined{" "}
                      {c.joined_at
                        ? new Date(c.joined_at).toLocaleDateString("en-US", {
                            month: "short",
                            day: "numeric",
                          })
                        : "—"}
                      {c.from_paper && " · from paper card"}
                    </p>
                  </td>
                  <td className="px-3 py-3.5">
                    <span
                      className={`whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-bold ${chip[c.status]}`}
                    >
                      {c.status}
                    </span>
                  </td>
                  <td className="px-3 py-3.5 text-right font-bold">
                    {c.visits}
                  </td>
                  <td className="whitespace-nowrap px-3 py-3.5 text-[#4E5A55]">
                    {c.lastLabel}
                  </td>
                  <td className="px-3 py-3.5">
                    <div className="flex items-center gap-2.5">
                      <div className="h-2 w-28 overflow-hidden rounded-full bg-[#EEF1EE]">
                        <div
                          className={`h-full rounded-full ${c.status === "Reward ready" ? "bg-[#C9735F]" : "bg-[#7E97A8]"}`}
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                      <span className="whitespace-nowrap text-xs font-bold">
                        {c.balance}/{needed}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-3.5 text-right font-bold">
                    {c.rewards}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        {/* nothing matched the filter or search */}
        {shown.length === 0 && (
          <p className="px-6 py-10 text-center text-sm text-[#6E7772]">
            No one matches that yet.
          </p>
        )}
      </div>
    </div>
  );
}
