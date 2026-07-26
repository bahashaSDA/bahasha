"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { ArrowLeft, CheckCircle2, Loader2, ShieldCheck, PlayCircle, BadgeCheck } from "lucide-react";
import { getSupabase, isSupabaseConfigured } from "@/lib/supabase";
import { apiCall } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

interface ConfigStatus {
  churchId: string;
  churchName: string;
  shortcode: string | null;
  hasPasskey: boolean;
  hasOwnApp: boolean;
  configured: boolean;
  validated: boolean;
  configuredAt: string | null;
}

// A video guide for getting M-Pesa Daraja credentials. Swap this for a specific
// video anytime; the search reliably surfaces up-to-date Safaricom tutorials.
const VIDEO_GUIDE_URL =
  "https://www.youtube.com/results?search_query=safaricom+daraja+api+go+live+get+consumer+key+passkey+tutorial";

/**
 * Self-service church payment onboarding. A church enters its OWN MPESA Daraja
 * credentials (paybill, passkey, and optionally its own Consumer Key/Secret so
 * giving runs on the church's own Daraja app — no aggregator, no fees). Secrets
 * are encrypted server-side and never shown again. A KSh 1 test verifies them
 * before any real giving is settled.
 */
export default function PaymentsPage() {
  const router = useRouter();
  const [churchId, setChurchId] = useState<string | null>(null);
  const [status, setStatus] = useState<ConfigStatus | null>(null);
  const [shortcode, setShortcode] = useState("");
  const [passkey, setPasskey] = useState("");
  const [consumerKey, setConsumerKey] = useState("");
  const [consumerSecret, setConsumerSecret] = useState("");
  const [testPhone, setTestPhone] = useState("");
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<"save" | "test" | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);
  const [showGuide, setShowGuide] = useState(false);

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

  async function refresh() {
    if (!churchId) return;
    setStatus(await apiCall<ConfigStatus>(`/churches/${churchId}/payment-config`));
  }

  async function save() {
    if (!churchId) return;
    setBusy("save");
    setError(null);
    setNotice(null);
    try {
      const body: Record<string, string> = { shortcode: shortcode.trim(), passkey: passkey.trim() };
      if (consumerKey.trim() && consumerSecret.trim()) {
        body.consumerKey = consumerKey.trim();
        body.consumerSecret = consumerSecret.trim();
      }
      await apiCall(`/churches/${churchId}/payment-config`, { method: "PUT", body });
      setPasskey("");
      setConsumerSecret("");
      setNotice("Saved. Now send a KSh 1 test to verify it works — giving only settles after a successful test.");
      await refresh();
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
      await refresh();
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
            {status?.validated ? (
              <Badge variant="success">Verified</Badge>
            ) : status?.configured ? (
              <Badge variant="warning">Test needed</Badge>
            ) : (
              <Badge variant="muted">Not set up</Badge>
            )}
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-3xl space-y-6 px-6 py-6">
        {error ? <div className="rounded-xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">{error}</div> : null}
        {notice ? <div className="rounded-xl border border-success/30 bg-success/10 px-4 py-3 text-sm">{notice}</div> : null}

        <Card>
          <CardHeader className="flex-row items-center gap-2">
            <ShieldCheck className="size-5 text-indigo dark:text-accent-violet" />
            <CardTitle className="text-base text-foreground">Your MPESA credentials</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Contributions to your church go <strong>directly into your own paybill</strong> — Bahasha never holds
              your money and takes <strong>no percentage</strong>. Everything below is encrypted and never shown again.
            </p>

            <Field label="Paybill / Till number" required>
              <input value={shortcode} onChange={(e) => setShortcode(e.target.value.replace(/\D/g, ""))}
                placeholder="e.g. 174379" inputMode="numeric"
                className="w-full rounded-lg border bg-background px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-ring" />
            </Field>

            <Field label="Passkey" required hint={status?.hasPasskey ? "saved — leave blank to keep" : "Lipa Na M-Pesa Online passkey"}>
              <input value={passkey} onChange={(e) => setPasskey(e.target.value)} type="password" autoComplete="off"
                placeholder={status?.hasPasskey ? "••••••••••••••••" : "Your passkey"}
                className="w-full rounded-lg border bg-background px-3 py-2.5 font-mono text-sm outline-none focus:ring-2 focus:ring-ring" />
            </Field>

            <div className="rounded-lg border border-dashed p-3">
              <p className="mb-3 text-sm font-medium">
                Your own Daraja app <span className="font-normal text-muted-foreground">(recommended — guarantees 0% fees)</span>
              </p>
              <div className="space-y-3">
                <Field label="Consumer Key" hint={status?.hasOwnApp ? "saved — leave blank to keep" : "optional"}>
                  <input value={consumerKey} onChange={(e) => setConsumerKey(e.target.value)} autoComplete="off"
                    placeholder={status?.hasOwnApp ? "•••••••• (saved)" : "From your Daraja app"}
                    className="w-full rounded-lg border bg-background px-3 py-2.5 font-mono text-sm outline-none focus:ring-2 focus:ring-ring" />
                </Field>
                <Field label="Consumer Secret" hint={status?.hasOwnApp ? "saved — leave blank to keep" : "optional"}>
                  <input value={consumerSecret} onChange={(e) => setConsumerSecret(e.target.value)} type="password" autoComplete="off"
                    placeholder={status?.hasOwnApp ? "••••••••••••••••" : "From your Daraja app"}
                    className="w-full rounded-lg border bg-background px-3 py-2.5 font-mono text-sm outline-none focus:ring-2 focus:ring-ring" />
                </Field>
              </div>
            </div>

            <button onClick={save}
              disabled={busy !== null || !shortcode || (!passkey && !status?.hasPasskey)}
              className="inline-flex items-center gap-2 rounded-lg bg-indigo px-4 py-2.5 text-sm font-medium text-white hover:opacity-90 disabled:opacity-50">
              {busy === "save" ? <Loader2 className="size-4 animate-spin" /> : <CheckCircle2 className="size-4" />}
              Save credentials
            </button>
          </CardContent>
        </Card>

        {status?.configured ? (
          <Card>
            <CardHeader className="flex-row items-center gap-2">
              {status.validated ? <BadgeCheck className="size-5 text-success" /> : null}
              <CardTitle className="text-base text-foreground">
                {status.validated ? "Verified — send another test anytime" : "Verify with a test"}
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground">
                Send a <strong>KSh 1</strong> MPESA prompt to a phone to confirm the money reaches your paybill.
                {status.validated ? "" : " Real giving only settles after a successful test."}
              </p>
              <div className="flex gap-2">
                <input value={testPhone} onChange={(e) => setTestPhone(e.target.value)} placeholder="07XX XXX XXX"
                  className="flex-1 rounded-lg border bg-background px-3 py-2.5 text-sm outline-none focus:ring-2 focus:ring-ring" />
                <button onClick={test} disabled={busy !== null || !testPhone}
                  className="inline-flex items-center gap-2 rounded-lg border px-4 py-2.5 text-sm font-medium hover:bg-muted disabled:opacity-50">
                  {busy === "test" ? <Loader2 className="size-4 animate-spin" /> : null}
                  Send KSh 1 test
                </button>
              </div>
            </CardContent>
          </Card>
        ) : null}

        {/* Guide for churches that don't have credentials yet */}
        <Card>
          <CardHeader className="flex-row items-center justify-between">
            <CardTitle className="text-base text-foreground">Don&apos;t have these yet?</CardTitle>
            <button onClick={() => setShowGuide((v) => !v)} className="text-sm text-indigo underline dark:text-accent-violet">
              {showGuide ? "Hide guide" : "Show step-by-step"}
            </button>
          </CardHeader>
          {showGuide ? (
            <CardContent className="space-y-4">
              <p className="text-sm text-muted-foreground">
                If your church has an MPESA <strong>paybill or till</strong> but hasn&apos;t set up the API yet, do this
                once to get your credentials:
              </p>
              <ol className="list-decimal space-y-2 pl-5 text-sm">
                <li>Open <strong>developer.safaricom.co.ke</strong> and create a free account (or sign in).</li>
                <li>Click <strong>My Apps → Create App</strong>. Tick <strong>Lipa Na M-Pesa Sandbox</strong> and <strong>M-Pesa Sandbox</strong>, then create it.</li>
                <li>Open the app — copy the <strong>Consumer Key</strong> and <strong>Consumer Secret</strong>.</li>
                <li>Go to <strong>Go Live</strong>. Choose <strong>Verification Type: Short Code</strong>, enter your <strong>paybill</strong>, your <strong>organization name</strong>, and your <strong>M-Pesa username</strong>.</li>
                <li>Safaricom sends a <strong>One-Time PIN to your M-Pesa admin&apos;s phone</strong> — enter it, and select the <strong>M-Pesa Express (Lipa Na M-Pesa Online)</strong> product.</li>
                <li>You now have your <strong>production Consumer Key, Consumer Secret, and Passkey</strong>. Paste all of them above and save.</li>
                <li>Send a KSh 1 test to confirm. Done — you never have to do this again.</li>
              </ol>
              <a href={VIDEO_GUIDE_URL} target="_blank" rel="noopener noreferrer"
                className="inline-flex items-center gap-2 rounded-lg bg-indigo px-4 py-2.5 text-sm font-medium text-white hover:opacity-90">
                <PlayCircle className="size-4" /> Watch a video guide
              </a>
              <p className="text-xs text-muted-foreground">
                The One-Time PIN goes only to your church&apos;s registered M-Pesa admin — Bahasha never sees it. This is
                Safaricom&apos;s security so only you can link your paybill.
              </p>
            </CardContent>
          ) : null}
        </Card>
      </main>
    </div>
  );
}

function Field({ label, hint, required, children }: { label: string; hint?: string; required?: boolean; children: React.ReactNode }) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-medium">
        {label} {required ? <span className="text-danger">*</span> : null}
        {hint ? <span className="ml-1 font-normal text-muted-foreground">({hint})</span> : null}
      </label>
      {children}
    </div>
  );
}
