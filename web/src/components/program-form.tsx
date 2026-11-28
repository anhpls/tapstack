"use client";

import { useActionState } from "react";
import { saveProgram, type ProgramState } from "@/app/business/rewards/actions";

type Program = {
  reward: string;
  stamps_needed: number;
  max_stamps_per_visit: number;
};

export function ProgramForm({
  program,
  canEdit,
}: {
  program: Program;
  canEdit: boolean;
}) {
  const [state, action, pending] = useActionState<ProgramState, FormData>(
    saveProgram,
    {},
  );

  return (
    <form
      action={action}
      className="mt-6 max-w-md space-y-5 rounded-2xl border border-[#E6E3DC] bg-white p-6"
    >
      {/* fieldset disabled = every input inside is read-only for staff */}
      <fieldset disabled={!canEdit || pending} className="space-y-5">
        <Field label="Reward" name="reward" defaultValue={program.reward} />
        <Field
          label="Stamps needed"
          name="stamps_needed"
          type="number"
          defaultValue={program.stamps_needed}
        />
        <Field
          label="Max stamps per visit"
          name="max_stamps_per_visit"
          type="number"
          defaultValue={program.max_stamps_per_visit}
        />
      </fieldset>

      {canEdit ? (
        <div className="flex items-center gap-3">
          <button
            className="rounded-full bg-[#1E2B2A] px-5 py-2 text-sm font-bold text-white disabled:opacity-50"
            disabled={pending}
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
          Only owners and managers can change the card.
        </p>
      )}
    </form>
  );
}

function Field({
  label,
  ...input
}: { label: string } & React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <label className="block">
      <span className="text-sm font-semibold text-[#4E5A55]">{label}</span>
      <input
        {...input}
        className="mt-1.5 w-full rounded-xl border border-[#E6E3DC] px-3 py-2 text-sm disabled:bg-[#F6F5F1]"
      />
    </label>
  );
}
