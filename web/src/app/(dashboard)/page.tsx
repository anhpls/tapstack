const stats = [
  { label: "New members", value: "220", note: "Last 12 weeks" },
  { label: "Back within 30 days", value: "46%", note: "Up from 31%" },
  { label: "Rewards redeemed", value: "64", note: "Free drinks earned" },
  { label: "Paper cards moved", value: "87", note: "Now digital" },
];

export default function OverviewPage() {
  return (
    <div className="mx-auto max-w-6xl">
      <h1 className="text-2xl font-semibold tracking-tight">Overview</h1>
      <p className="mt-1 text-sm text-neutral-500">
        Sample data · Your shop at a glance
      </p>

      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((s) => (
          <div
            key={s.label}
            className="rounded-2xl border border-neutral-200 bg-white p-5"
          >
            <p className="text-sm text-neutral-500">{s.label}</p>
            <p className="mt-2 text-3xl font-semibold tracking-tight">
              {s.value}
            </p>
            <p className="mt-1 text-xs text-emerald-700">{s.note}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
