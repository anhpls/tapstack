"use client";

import { useActionState, useState, useTransition } from "react";
import {
  inviteMember,
  changeRole,
  removeMember,
  cancelInvite,
  type TeamState,
} from "@/app/business/settings/actions";
import type { StaffShop } from "@/lib/auth";

type Role = StaffShop["role"];
type Member = { user_id: string; email: string; role: Role; is_you: boolean };
type Invite = { id: string; email: string; role: Role };

export function Team({
  members,
  invites,
  myRole,
}: {
  members: Member[];
  invites: Invite[];
  myRole: Role;
}) {
  const isOwner = myRole === "owner";
  const [state, action, inviting] = useActionState<TeamState, FormData>(
    inviteMember,
    {},
  );
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  // run an action and show its error if it has one
  const run = (fn: () => Promise<string | null | void>) =>
    startTransition(async () => setError((await fn()) || null));

  const box = "rounded-xl border border-[#E6E3DC] px-3 py-2 text-sm";

  return (
    <div className="mt-4 max-w-2xl space-y-4">
      <ul className="rounded-2xl border border-[#E6E3DC] bg-white">
        {members.map((m) => {
          // managers can only remove staff, nobody removes themselves here
          const canRemove = !m.is_you && (isOwner || m.role === "staff");
          return (
            <li
              key={m.user_id}
              className="flex items-center justify-between gap-4 border-t border-[#EFEDE7] px-6 py-3.5 first:border-t-0"
            >
              <p className="truncate text-sm font-semibold">
                {m.email}{" "}
                {m.is_you && (
                  <span className="font-normal text-[#6E7772]">(you)</span>
                )}
              </p>
              <div className="flex items-center gap-2">
                {isOwner ? (
                  <select
                    value={m.role}
                    disabled={pending}
                    onChange={(e) =>
                      run(() => changeRole(m.user_id, e.target.value as Role))
                    }
                    className={box}
                  >
                    <option value="owner">Owner</option>
                    <option value="manager">Manager</option>
                    <option value="staff">Staff</option>
                  </select>
                ) : (
                  <span className="text-sm capitalize text-[#4E5A55]">
                    {m.role}
                  </span>
                )}
                {canRemove && (
                  <button
                    disabled={pending}
                    onClick={() => run(() => removeMember(m.user_id))}
                    className="rounded-full border border-[#E6E3DC] px-3 py-1.5 text-xs font-bold hover:border-[#9A4A38] hover:text-[#9A4A38]"
                  >
                    Remove
                  </button>
                )}
              </div>
            </li>
          );
        })}
      </ul>
      {error && <p className="text-sm text-[#9A4A38]">{error}</p>}

      {invites.length > 0 && (
        <ul className="rounded-2xl border border-dashed border-[#E6E3DC] bg-white">
          {invites.map((i) => (
            <li
              key={i.id}
              className="flex items-center justify-between gap-4 border-t border-[#EFEDE7] px-6 py-3 first:border-t-0"
            >
              <p className="text-sm">
                {i.email}{" "}
                <span className="text-[#6E7772]">
                  · invited as {i.role}, waiting for them to sign in
                </span>
              </p>
              <button
                disabled={pending}
                onClick={() => run(() => cancelInvite(i.id))}
                className="text-xs font-bold text-[#6E7772] hover:text-[#9A4A38]"
              >
                Cancel
              </button>
            </li>
          ))}
        </ul>
      )}

      <form action={action} className="flex flex-wrap items-center gap-2">
        <input
          name="email"
          type="email"
          required
          placeholder="name@email.com"
          className={`${box} min-w-64 flex-1 bg-white`}
        />
        <select name="role" defaultValue="staff" className={`${box} bg-white`}>
          <option value="staff">Staff</option>
          {isOwner && <option value="manager">Manager</option>}
          {isOwner && <option value="owner">Owner</option>}
        </select>
        <button
          disabled={inviting}
          className="rounded-full bg-[#1E2B2A] px-5 py-2 text-sm font-bold text-white disabled:opacity-50"
        >
          {inviting ? "Inviting…" : "Invite"}
        </button>
        {state.saved && <span className="text-sm text-[#3F7A58]">Invited</span>}
        {state.error && (
          <span className="text-sm text-[#9A4A38]">{state.error}</span>
        )}
      </form>
    </div>
  );
}
