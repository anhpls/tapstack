"use client";

import { useActionState, useState } from "react";
import { addDeal, type DealState } from "@/app/business/deals/actions";

// datetime-local has no timezone, so convert to a real utc time here in the browser
const toIso = (v: string) => (v ? new Date(v).toISOString() : "");

export function DealForm() {
  const [state, action, pending] = useActionState<DealState, FormData>(
    addDeal,
    {},
  );
  const [start, setStart] = useState("");
  const [end, setEnd] = useState("");

  return (
    <form
      action={action}
      className="mt-6 grid max-w-3xl gap-4 rounded-2xl border border-[#E6E3DC] bg-white p-6 sm:grid-cols-2"
    >
      <label className="block sm:col-span-2">
        <span className="text-sm font-semibold text-[#4E5A55]">Name</span>
        <input
          name="name"
          placeholder="Double stamp weekend"
          required
          className="mt-1.5 w-full rounded-xl border border-[#E6E3DC] px-3 py-2 text-sm"
        />
      </label>

      <label className="block">
        <span className="text-sm font-semibold text-[#4E5A55]">Starts</span>
        <input
          type="datetime-local"
          value={start}
          onChange={(e) => setStart(e.target.value)}
          required
          className="mt-1.5 w-full rounded-xl border border-[#E6E3DC] px-3 py-2 text-sm"
        />
      </label>
      <label className="block">
        <span className="text-sm font-semibold text-[#4E5A55]">Ends</span>
        <input
          type="datetime-local"
          value={end}
          onChange={(e) => setEnd(e.target.value)}
          required
          className="mt-1.5 w-full rounded-xl border border-[#E6E3DC] px-3 py-2 text-sm"
        />
      </label>
      {/* what actually gets sent */}
      <input type="hidden" name="starts_at" value={toIso(start)} />
      <input type="hidden" name="ends_at" value={toIso(end)} />

      <label className="block">
        <span className="text-sm font-semibold text-[#4E5A55]">
          Stamps per purchase
        </span>
        <select
          name="multiplier"
          defaultValue="2"
          className="mt-1.5 w-full rounded-xl border border-[#E6E3DC] px-3 py-2 text-sm"
        >
          {[2, 3, 4, 5].map((m) => (
            <option key={m} value={m}>
              {m}x
            </option>
          ))}
        </select>
      </label>

      <div className="flex items-end gap-3">
        <button
          disabled={pending}
          className="rounded-full bg-[#1E2B2A] px-5 py-2 text-sm font-bold text-white disabled:opacity-50"
        >
          {pending ? "Adding…" : "Add deal"}
        </button>
        {state.saved && <span className="text-sm text-[#3F7A58]">Added</span>}
        {state.error && (
          <span className="text-sm text-[#9A4A38]">{state.error}</span>
        )}
      </div>
    </form>
  );
}
