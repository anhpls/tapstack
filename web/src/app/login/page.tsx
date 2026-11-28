"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const supabase = createClient();
  const router = useRouter();

  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [step, setStep] = useState<"email" | "code">("email");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  // step 1: email them a 6 digit code
  async function sendCode(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const { error } = await supabase.auth.signInWithOtp({
      email,
      // no surprise sign ups from the web, you need an account from the app first
      options: { shouldCreateUser: false },
    });
    setBusy(false);
    if (error) return setError(error.message);
    setStep("code");
  }

  // step 2: check the code, then head into the dashboard
  async function verifyCode(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const { error } = await supabase.auth.verifyOtp({
      email,
      token: code,
      type: "email",
    });
    setBusy(false);
    if (error) return setError(error.message);
    router.replace("/");
    router.refresh(); // makes the server re-read the new session cookie
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-[#F6F5F1] px-6">
      <div className="w-full max-w-sm rounded-2xl border border-[#E6E3DC] bg-white p-8">
        <h1 className="text-2xl font-bold text-[#1E2B2A]">
          Sign in to Tapstack
        </h1>
        <p className="mt-1 text-sm text-[#6E7772]">
          {step === "email"
            ? "Use the email on your Tapstack account."
            : `We sent a code to ${email}.`}
        </p>

        {step === "email" ? (
          <form onSubmit={sendCode} className="mt-6 space-y-3">
            <label
              className="block text-sm font-semibold text-[#1E2B2A]"
              htmlFor="email"
            >
              Email
            </label>
            <input
              id="email"
              type="email"
              required
              autoComplete="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded-xl border border-[#E6E3DC] px-4 py-3 text-[#1E2B2A] outline-none focus:border-[#1E2B2A]"
            />
            <button
              disabled={busy}
              className="w-full rounded-full bg-[#1E2B2A] py-3 font-bold text-white disabled:opacity-60"
            >
              {busy ? "Sending..." : "Send code"}
            </button>
          </form>
        ) : (
          <form onSubmit={verifyCode} className="mt-6 space-y-3">
            <label
              className="block text-sm font-semibold text-[#1E2B2A]"
              htmlFor="code"
            >
              8-digit code
            </label>
            <input
              id="code"
              inputMode="numeric"
              autoComplete="one-time-code"
              maxLength={8}
              required
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
              className="w-full rounded-xl border border-[#E6E3DC] px-4 py-3 text-center font-mono text-xl tracking-[0.4em] text-[#1E2B2A] outline-none focus:border-[#1E2B2A]"
            />
            <button
              disabled={busy || code.length < 8}
              className="w-full rounded-full bg-[#1E2B2A] py-3 font-bold text-white disabled:opacity-60"
            >
              {busy ? "Checking..." : "Sign in"}
            </button>
            <button
              type="button"
              onClick={() => setStep("email")}
              className="w-full text-sm font-semibold text-[#6E7772]"
            >
              Use a different email
            </button>
          </form>
        )}

        {error && (
          <p className="mt-4 text-sm font-semibold text-[#9A4A38]">{error}</p>
        )}
      </div>
    </main>
  );
}
