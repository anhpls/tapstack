"use client";

import { useActionState, useState } from "react";
import { saveShop, type ShopState } from "@/app/business/settings/actions";

type Shop = { name: string; category: string; color_hex: string };

export function ShopForm({ shop, canEdit }: { shop: Shop; canEdit: boolean }) {
  const [state, action, pending] = useActionState<ShopState, FormData>(
    saveShop,
    {},
  );
  const [color, setColor] = useState(shop.color_hex);

  const input =
    "mt-1.5 w-full rounded-xl border border-[#E6E3DC] px-3 py-2 text-sm disabled:bg-[#F6F5F1]";

  return (
    <form
      action={action}
      className="mt-4 max-w-md space-y-5 rounded-2xl border border-[#E6E3DC] bg-white p-6"
    >
      <fieldset disabled={!canEdit || pending} className="space-y-5">
        <label className="block">
          <span className="text-sm font-semibold text-[#4E5A55]">
            Shop name
          </span>
          <input
            name="name"
            defaultValue={shop.name}
            maxLength={60}
            required
            className={input}
          />
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-[#4E5A55]">Category</span>
          <select
            name="category"
            defaultValue={shop.category}
            className={input}
          >
            <option value="cafe">Cafe</option>
            <option value="boba">Boba</option>
            <option value="restaurant">Restaurant</option>
            <option value="bakery">Bakery</option>
          </select>
        </label>

        <label className="block">
          <span className="text-sm font-semibold text-[#4E5A55]">
            Card color
          </span>
          <div className="mt-1.5 flex items-center gap-3">
            <input
              type="color"
              name="color_hex"
              value={color}
              onChange={(e) => setColor(e.target.value)}
              className="h-10 w-14 cursor-pointer rounded-lg border border-[#E6E3DC]"
            />
            {/* little preview of how the card color reads */}
            <span
              className="rounded-full px-3 py-1 font-mono text-xs font-bold text-white"
              style={{ background: color }}
            >
              {color.toUpperCase()}
            </span>
          </div>
        </label>
      </fieldset>

      {canEdit ? (
        <div className="flex items-center gap-3">
          <button
            disabled={pending}
            className="rounded-full bg-[#1E2B2A] px-5 py-2 text-sm font-bold text-white disabled:opacity-50"
          >
            {pending ? "Saving…" : "Save"}
          </button>
          {state.saved && <span className="text-sm text-[#3F7A58]">Saved</span>}
          {state.error && (
            <span className="text-sm text-[#9A4A38]">{state.error}</span>
          )}
        </div>
      ) : (
        <p className="text-sm text-[#6E7772]">
          Only owners and managers can edit the shop.
        </p>
      )}
    </form>
  );
}
