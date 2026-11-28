"use client";

import { useEffect, useState } from "react";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { Search } from "lucide-react";

export function CustomerSearch() {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const [q, setQ] = useState(params.get("q") ?? "");

  // wait till they stop typing for a sec, then put it in the url
  useEffect(() => {
    const t = setTimeout(() => {
      const next = new URLSearchParams(params);
      if (q) next.set("q", q);
      else next.delete("q");
      if (next.toString() !== params.toString()) {
        router.replace(`${pathname}?${next}`, { scroll: false }); // replace so typing doesn't spam history
      }
    }, 250);
    return () => clearTimeout(t);
  }, [q, params, pathname, router]);

  return (
    <label className="flex h-11 min-w-70 items-center gap-2.5 rounded-full border border-[#E6E3DC] bg-white px-4">
      <Search className="h-4 w-4 text-[#6E7772]" />
      <span className="sr-only">Search members</span>
      <input
        type="search"
        value={q}
        onChange={(e) => setQ(e.target.value)}
        placeholder="Search member number"
        className="flex-1 bg-transparent text-sm outline-none"
      />
    </label>
  );
}
