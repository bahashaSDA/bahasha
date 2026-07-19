"use client";

import { useState, type FormEvent } from "react";
import { useRouter } from "next/navigation";
import { Wallet, Loader2 } from "lucide-react";
import { signIn } from "@/lib/use-auth";
import { isSupabaseConfigured } from "@/lib/supabase";

/**
 * Treasurer sign-in. Authenticates against Supabase Auth; on success the
 * dashboard shows this treasurer's own church data (RLS-scoped). If Supabase is
 * not configured yet, the page explains how to proceed with demo data.
 */
export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const configured = isSupabaseConfigured();

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setBusy(true);
    try {
      await signIn(email, password);
      router.push("/dashboard");
    } catch (err) {
      setError(err instanceof Error ? err.message : "Sign in failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="grid min-h-dvh place-items-center px-4">
      <div className="w-full max-w-sm">
        <div className="mb-8 flex flex-col items-center text-center">
          <div className="grid size-12 place-items-center rounded-2xl bg-indigo text-white">
            <Wallet className="size-6" />
          </div>
          <h1 className="mt-4 text-2xl font-semibold">Bahasha Treasurer</h1>
          <p className="mt-1 text-sm text-muted-foreground">Sign in to view your church&apos;s giving</p>
        </div>

        {!configured ? (
          <div className="rounded-xl border border-warning/30 bg-warning/10 p-4 text-sm">
            Supabase is not configured. Set <code>NEXT_PUBLIC_SUPABASE_URL</code> and{" "}
            <code>NEXT_PUBLIC_SUPABASE_ANON_KEY</code> in <code>.env.local</code>, or{" "}
            <a href="/dashboard" className="font-medium text-indigo underline">
              continue with demo data
            </a>
            .
          </div>
        ) : (
          <form onSubmit={onSubmit} className="space-y-4">
            <div>
              <label className="mb-1.5 block text-sm font-medium" htmlFor="email">
                Email
              </label>
              <input
                id="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full rounded-lg border bg-background px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-ring"
                placeholder="treasurer@church.org"
              />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-medium" htmlFor="password">
                Password
              </label>
              <input
                id="password"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full rounded-lg border bg-background px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-ring"
                placeholder="••••••••"
              />
            </div>

            {error ? <p className="text-sm text-danger">{error}</p> : null}

            <button
              type="submit"
              disabled={busy}
              className="flex w-full items-center justify-center gap-2 rounded-lg bg-indigo px-4 py-2.5 text-sm font-medium text-white transition hover:opacity-90 disabled:opacity-60"
            >
              {busy ? <Loader2 className="size-4 animate-spin" /> : null}
              Sign in
            </button>

            <p className="text-center text-xs text-muted-foreground">
              <a href="/dashboard" className="underline">
                View demo dashboard
              </a>
            </p>
          </form>
        )}
      </div>
    </div>
  );
}
