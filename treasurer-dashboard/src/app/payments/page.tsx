"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowLeft, CheckCircle2, Loader2, ShieldCheck, Info } from "lucide-react";
import { getSupabase, isSupabaseConfigured } from "@/lib/supabase";
import { apiCall } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

interface ConfigStatus {
  churchId: string;
  churchName: string;
  shortcode: string | null;
  hasPasskey: boolean;
  configured: boolean;
  configuredAt: string | null;
}

/**
 * Self-service church payment onboarding. A treasurer sets their OWN paybill +
 * Lipa Na M-Pesa Online passkey so contributions settle directly into their
 * church. The passkey is sent once over HTTPS, encrypted server-side, and never
 * shown again. A test button fires a KSh 1 STK Push to confirm it works.
 */
export default function PaymentsPage() {
  const router = useRouter();
  const [churchId, setChurchId] = useState<string | null>(null);
  const [status, setStatus] = useState<ConfigStatus | null>(null);
  const [shortcode, setShortcode] = useState("");
  const [passkey, setPasskey] = useState("");
  const [testPhone, setTestPhone] = useState("");
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<"save" | "test" | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      if (!isSupabaseConfigured()) {
        setError("Supabase is not configured.");
        setLoading(false);
        return;
      }
      const supabase = getSupabase();
      const { data: session } = await supabase.auth.getSession();
      if (!session.session) {
        router.push("/login");
        return;
      }
      // Resolve this treasurer's church (admins may not have one → prompt).
      const { data: treasurer } = await supabase
        .from("treasurers")
        .select("church_id")
        .eq("id", session.session.user.id)
        .maybeSingle();
      const cid = treasurer?.church_id as string | undefined;
      if (!cid) {
        setError("This account is not linked to a church.");
        setLoading(false);
        return;
      }
      setChurchId(cid);
      try {
        const s = await apiCall<ConfigStatus>(`/churches/${cid}/payment-config`);
        setStatus(s);
        if (s.shortcode) setShortcode(s.shortcode);
      } catch (e) {
        setError(e instanceof Error ? e.message : "Failed to load");
      } finally {
        setLoading(false);
      }
    })();
  }, [router]);

  async function save() {
    if (!churchId) return;
    setBusy("save");
    setError(null);
    setNotice(null);
    try {
      await apiCall(`/churches/${churchId}/payment-config`, {
        method: "PUT",
        body: { shortcode: shortcode.trim(), passkey: passkey.trim() },
      });
      setPasskey("");
      setNotice("Saved. Your paybill is now set — send a test to confirm it works.");
      const s = await apiCall<ConfigStatus>(`/churches/${churchId}/payment-config`);
      setStatus(s);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not save");
    } finally {
      setBusy(null);
    }
  }

  async function test() {
    if (!churchId) return;
    setBusy("test");
    setError(null);
    setNotice(null);
    try {
      const r = await apiCall<{ message: string }>(`/churches/${churchId}/payment-config/test`, {
        method: "POST",
        body: { phone: testPhone.trim() },
      });
      setNotice(r.message);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Test failed");
    } finally {
      setBusy(null);
    }
  }

  if (loading) {
    return (
      <div className="grid min-h-dvh place-items-center">
        <Loader2 className="size-6 animate-spin text-muted-foreground" />
      </div>
    );
  }

  return (
    <div className="min-h-dvh">
      <header className="border-b bg-background/80 backdrop-blur">
        <div className="mx-auto flex max-w-3xl items-center gap-3 px-6 py-4">
          <button onClick={() => router.push("/dashboard")} className="inline-flex items-center gap-2 rounded-lg border px-3 py-2 text-sm hover:bg-muted">
            <ArrowLeft className="size-4" /> Dashboard
          </button>
          <div>
            <h1 className="text-lg font-semibold leading-tight">Payment setup</h1>
            <p className="text-xs text-muted-foreground">{status?.churchName ?? "Your church"}</p>
          </div>
          <div className="ml-auto">
            {status?.configured ? <Badge variant="success">Configured</Badge> : <Badge variant="warning">Not set up</Badge>}
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-3xl space-y-6 px-6 py-6">
        {error ? <div className="rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">{error}</div> : null}
        {notice ? <div className="rounded-xl border border-success/30 bg-success/10 px-4 py-3 text-sm">{notice}</div> : null}

        <Card>
          <CardHeader className="flex-row items-center gap-2">
            <ShieldCheck className="size-5 text-indigo dark:text-accent-violet" />
            <CardTitle className="text-base text-foreground">Your MPESA paybill</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Contributions to your church go <strong>directly into your own paybill</strong> — Bahasha never holds
              your money. Enter your paybill and its Lipa&nbsp;Na&nbsp;M-Pesa Online passkey below.
            </p>

            <div>
              <label className="mb-1.5 block text-sm font-medium">Paybill / Till number</label>
              <input
                value={shortcode}
                onChange={(e) => setShortcode(e.target.value.replace(/\D/g, ""))}
                placeholder="e.g. 174379"
                inputMode="numeric"
                className="w-full rounded-lg border bg-background px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-ring"
              />
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-medium">
                Passkey {status?.hasPasskey ? <span className="text-muted-foreground">(saved — leave blank to keep)</span> : null}
              </label>
              <input
                value={passkey}
                onChange={(e) => setPasskey(e.target.value)}
                type="password"
                placeholder={status?.hasPasskey ? "••••••••••••••••" : "Your LNM Online passkey"}
                autoComplete="off"
                className="w-full rounded-lg border bg-background px-3 py-2.5 font-mono text-sm outline-none focus:ring-2 focus:ring-ring"
              />
              <p className="mt-1 text-xs text-muted-foreground">Stored encrypted. It is never shown again after saving.</p>
            </div>

            <button
              onClick={save}
              disabled={busy !== null || !shortcode || (!passkey && !status?.hasPasskey)}
              className="inline-flex items-center gap-2 rounded-lg bg-indigo px-4 py-2.5 text-sm font-medium text-white hover:opacity-90 disabled:opacity-50"
            >
              {busy === "save" ? <Loader2 className="size-4 animate-spin" /> : <CheckCircle2 className="size-4" />}
              Save paybill
            </button>
          </CardContent>
        </Card>

        {status?.configured ? (
          <Card>
            <CardHeader>
              <CardTitle className="text-base text-foreground">Send a test</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground">
                Send a <strong>KSh 1</strong> MPESA prompt to a phone to confirm the money reaches your paybill.
              </p>
              <div className="flex gap-2">
                <input
                  value={testPhone}
                  onChange={(e) => setTestPhone(e.target.value)}
                  placeholder="07XX XXX XXX"
                  className="flex-1 rounded-lg border bg-background px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-ring"
                />
                <button
                  onClick={test}
                  disabled={busy !== null || !testPhone}
                  className="inline-flex items-center gap-2 rounded-lg border px-4 py-2.5 text-sm font-medium hover:bg-muted disabled:opacity-50"
                >
                  {busy === "test" ? <Loader2 className="size-4 animate-spin" /> : null}
                  Send test
                </button>
              </div>
            </CardContent>
          </Card>
        ) : null}

        <Card>
          <CardHeader className="flex-row items-center gap-2">
            <Info className="size-5 text-muted-foreground" />
            <CardTitle className="text-base text-foreground">How to get your passkey</CardTitle>
          </CardHeader>
          <CardContent>
            <ol className="list-decimal space-y-2 pl-5 text-sm text-muted-foreground">
              <li>Make sure your church has an MPESA <strong>Paybill or Till</strong> (from Safaricom).</li>
              <li>Go to <strong>developer.safaricom.co.ke</strong> and sign in (or your M-Pesa Business/Org portal).</li>
              <li>Under <strong>Lipa Na M-Pesa Online (M-Pesa Express)</strong>, enable it for your shortcode.</li>
              <li>Copy the <strong>Passkey</strong> shown for your paybill and paste it above.</li>
              <li>Save, then send a KSh 1 test to confirm it works.</li>
            </ol>
          </CardContent>
        </Card>
      </main>
    </div>
  );
}
