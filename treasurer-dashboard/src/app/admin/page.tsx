"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import {
  Shield,
  Building2,
  Users,
  EyeOff,
  Radio,
  LogOut,
  Moon,
  Sun,
  Eye,
  Loader2,
  ArrowLeft,
} from "lucide-react";
import { BarChart, Bar, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { StatCard } from "@/components/dashboard/stat-card";
import { useTheme } from "@/components/theme-provider";
import { signOut } from "@/lib/use-auth";
import { formatKes, formatNumber } from "@/lib/utils";
import {
  useIsSuperAdmin,
  fetchChurchSummary,
  fetchGivers,
  fetchHubs,
  fetchReveals,
  revealIdentity,
  type ChurchSummary,
  type AdminGiver,
  type AdminHub,
  type RevealLog,
} from "@/lib/use-admin";

const PALETTE = ["#231F4F", "#89D385", "#6CD1F0", "#A1A1F7", "#2f9e44", "#e8a13a"];

export default function AdminPage() {
  const router = useRouter();
  const { theme, toggle } = useTheme();
  const { isSuperAdmin, loading, signedIn } = useIsSuperAdmin();

  const [churches, setChurches] = useState<ChurchSummary[]>([]);
  const [givers, setGivers] = useState<AdminGiver[]>([]);
  const [hubs, setHubs] = useState<AdminHub[]>([]);
  const [reveals, setReveals] = useState<RevealLog[]>([]);
  const [dataLoading, setDataLoading] = useState(true);

  useEffect(() => {
    if (loading) return;
    if (!signedIn) {
      router.push("/login");
      return;
    }
    if (!isSuperAdmin) {
      setDataLoading(false);
      return;
    }
    (async () => {
      try {
        const [c, g, h, r] = await Promise.all([
          fetchChurchSummary(),
          fetchGivers(),
          fetchHubs(),
          fetchReveals(),
        ]);
        setChurches(c);
        setGivers(g);
        setHubs(h);
        setReveals(r);
      } finally {
        setDataLoading(false);
      }
    })();
  }, [loading, signedIn, isSuperAdmin, router]);

  const totals = useMemo(() => {
    const totalGiven = churches.reduce((s, c) => s + Number(c.total_given), 0);
    const givers_ = churches.reduce((s, c) => s + Number(c.giver_count), 0);
    const anon = churches.reduce((s, c) => s + Number(c.anonymous_giver_count), 0);
    const onlineHubs = hubs.filter((h) => h.status === "online").length;
    return { totalGiven, givers: givers_, anon, hubs: hubs.length, onlineHubs };
  }, [churches, hubs]);

  async function onReveal(userId: string): Promise<void> {
    const reason = window.prompt(
      "Reveal this anonymous giver's identity.\n\nThis action is permanently logged with your name.\nEnter a reason (min 10 characters):",
    );
    if (!reason) return;
    if (reason.trim().length < 10) {
      alert("A reason of at least 10 characters is required.");
      return;
    }
    try {
      const id = await revealIdentity(userId, reason.trim());
      alert(`Identity: ${id.full_name}\nPhone: ${id.phone}\nChurch: ${id.church_name}\n\nThis reveal has been logged.`);
      setReveals(await fetchReveals());
    } catch (e) {
      alert(`Could not reveal: ${e instanceof Error ? e.message : e}`);
    }
  }

  if (loading || dataLoading) {
    return (
      <div className="grid min-h-dvh place-items-center">
        <Loader2 className="size-6 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (!isSuperAdmin) {
    return (
      <div className="grid min-h-dvh place-items-center px-4">
        <Card className="max-w-sm p-6 text-center">
          <Shield className="mx-auto size-8 text-muted-foreground" />
          <h1 className="mt-3 text-lg font-semibold">Super admin only</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            This area is restricted to Bahasha platform administrators.
          </p>
          <button
            onClick={() => router.push("/dashboard")}
            className="mt-4 rounded-lg bg-indigo px-4 py-2 text-sm text-white"
          >
            Back to dashboard
          </button>
        </Card>
      </div>
    );
  }

  const chartData = churches.map((c) => ({ name: c.church_name.replace(/ SDA Church$/, ""), value: Number(c.total_given) }));

  return (
    <div className="min-h-dvh">
      <header className="sticky top-0 z-10 border-b bg-background/80 backdrop-blur">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="grid size-9 place-items-center rounded-xl bg-indigo text-white">
              <Shield className="size-5" />
            </div>
            <div>
              <h1 className="text-lg font-semibold leading-tight">Bahasha Super Admin</h1>
              <p className="text-xs text-muted-foreground">Network oversight · all churches</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => router.push("/dashboard")}
              className="inline-flex items-center gap-2 rounded-lg border px-3 py-2 text-sm hover:bg-muted"
            >
              <ArrowLeft className="size-4" /> Treasurer view
            </button>
            <button onClick={toggle} aria-label="Theme" className="grid size-9 place-items-center rounded-lg border hover:bg-muted">
              {theme === "dark" ? <Sun className="size-4" /> : <Moon className="size-4" />}
            </button>
            <button
              onClick={async () => {
                await signOut();
                router.push("/login");
              }}
              aria-label="Sign out"
              className="grid size-9 place-items-center rounded-lg border hover:bg-muted"
            >
              <LogOut className="size-4" />
            </button>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-7xl space-y-6 px-6 py-6">
        {/* Network totals */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard index={0} label="Total received (network)" value={formatKes(totals.totalGiven)} icon={Building2} accent="indigo" />
          <StatCard index={1} label="Churches" value={formatNumber(churches.length)} icon={Building2} accent="green" />
          <StatCard index={2} label="Total givers" value={formatNumber(totals.givers)} sub={`${formatNumber(totals.anon)} anonymous`} icon={Users} accent="cyan" />
          <StatCard index={3} label="Hubs online" value={`${totals.onlineHubs}/${totals.hubs}`} icon={Radio} accent="violet" />
        </div>

        {/* Giving by church */}
        <Card>
          <CardHeader>
            <CardTitle>Giving by church</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-64 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData} margin={{ left: 8, right: 8 }}>
                  <XAxis dataKey="name" tickLine={false} axisLine={false} fontSize={12} />
                  <YAxis tickFormatter={(v) => formatKes(v as number, { compact: true })} tickLine={false} axisLine={false} width={64} fontSize={12} />
                  <Tooltip
                    content={({ active, payload, label }) =>
                      active && payload?.length ? (
                        <div className="rounded-lg border bg-card px-3 py-2 text-sm shadow-md">
                          <p className="font-medium">{label}</p>
                          <p className="text-muted-foreground">{formatKes(payload[0].value as number)}</p>
                        </div>
                      ) : null
                    }
                  />
                  <Bar dataKey="value" radius={[6, 6, 0, 0]}>
                    {chartData.map((_, i) => (
                      <Cell key={i} fill={PALETTE[i % PALETTE.length]} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>

        {/* Churches table */}
        <Card>
          <CardHeader>
            <CardTitle>Churches</CardTitle>
          </CardHeader>
          <CardContent className="pt-0">
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-xs uppercase text-muted-foreground">
                    <th className="py-2.5 pr-4 font-medium">Church</th>
                    <th className="py-2.5 pr-4 font-medium">City</th>
                    <th className="py-2.5 pr-4 text-right font-medium">Received</th>
                    <th className="py-2.5 pr-4 text-right font-medium">Givers</th>
                    <th className="py-2.5 pr-4 text-right font-medium">Anonymous</th>
                    <th className="py-2.5 font-medium">Hub</th>
                  </tr>
                </thead>
                <tbody>
                  {churches.map((c) => (
                    <tr key={c.church_id} className="border-b last:border-0">
                      <td className="py-3 pr-4 font-medium">{c.church_name}</td>
                      <td className="py-3 pr-4 text-muted-foreground">{c.city ?? "—"}</td>
                      <td className="py-3 pr-4 text-right tabular-nums">{formatKes(Number(c.total_given))}</td>
                      <td className="py-3 pr-4 text-right tabular-nums">{formatNumber(Number(c.giver_count))}</td>
                      <td className="py-3 pr-4 text-right tabular-nums">{formatNumber(Number(c.anonymous_giver_count))}</td>
                      <td className="py-3">
                        <Badge variant={c.hub_status === "online" ? "success" : c.hub_status ? "warning" : "muted"}>
                          {c.hub_status ?? "no hub"}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>

        {/* Givers with audited reveal */}
        <Card>
          <CardHeader>
            <CardTitle>Givers — identity resolution (audited)</CardTitle>
          </CardHeader>
          <CardContent className="pt-0">
            <p className="mb-3 text-sm text-muted-foreground">
              Anonymous givers are masked. Revealing an identity is permanently logged with your name and a reason.
            </p>
            <div className="max-h-96 overflow-auto">
              <table className="w-full text-sm">
                <thead className="sticky top-0 bg-card">
                  <tr className="border-b text-left text-xs uppercase text-muted-foreground">
                    <th className="py-2.5 pr-4 font-medium">Giver</th>
                    <th className="py-2.5 pr-4 font-medium">Church</th>
                    <th className="py-2.5 pr-4 text-right font-medium">Given</th>
                    <th className="py-2.5 font-medium"></th>
                  </tr>
                </thead>
                <tbody>
                  {givers.map((g) => (
                    <tr key={g.user_id} className="border-b last:border-0">
                      <td className="py-3 pr-4">
                        <span className="flex items-center gap-2">
                          <span className="font-medium">{g.visibility === "secret" ? g.pseudonym : g.display_name}</span>
                          {g.visibility === "secret" ? <Badge variant="violet">Secret</Badge> : null}
                        </span>
                      </td>
                      <td className="py-3 pr-4 text-muted-foreground">{g.church_name.replace(/ SDA Church$/, "")}</td>
                      <td className="py-3 pr-4 text-right tabular-nums">{formatKes(Number(g.total_given))}</td>
                      <td className="py-3 text-right">
                        {g.visibility === "secret" ? (
                          <button
                            onClick={() => onReveal(g.user_id)}
                            className="inline-flex items-center gap-1.5 rounded-lg border px-2.5 py-1.5 text-xs hover:bg-muted"
                          >
                            <Eye className="size-3.5" /> Reveal
                          </button>
                        ) : (
                          <EyeOff className="ml-auto size-4 text-muted-foreground/40" />
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>

        {/* Hubs + reveal audit log */}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>Bluetooth hubs</CardTitle>
            </CardHeader>
            <CardContent className="pt-0">
              {hubs.length === 0 ? (
                <p className="py-4 text-sm text-muted-foreground">No hubs registered yet.</p>
              ) : (
                <div className="space-y-2">
                  {hubs.map((h) => (
                    <div key={h.hub_id} className="flex items-center justify-between rounded-lg border p-3">
                      <div>
                        <p className="font-medium">{h.church_name.replace(/ SDA Church$/, "")}</p>
                        <p className="text-xs text-muted-foreground">
                          {h.last_upload_at ? `Last upload ${new Date(h.last_upload_at).toLocaleString()}` : "No uploads yet"}
                        </p>
                      </div>
                      <Badge variant={h.status === "online" ? "success" : "muted"}>{h.status}</Badge>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Identity reveal log</CardTitle>
            </CardHeader>
            <CardContent className="pt-0">
              {reveals.length === 0 ? (
                <p className="py-4 text-sm text-muted-foreground">No identities have been revealed.</p>
              ) : (
                <div className="max-h-64 space-y-2 overflow-auto">
                  {reveals.map((r, i) => (
                    <div key={i} className="rounded-lg border p-3 text-sm">
                      <div className="flex items-center justify-between">
                        <span className="font-medium">{r.admin_name}</span>
                        <span className="text-xs text-muted-foreground">{new Date(r.revealed_at).toLocaleString()}</span>
                      </div>
                      <p className="text-muted-foreground">
                        {r.giver_church} — “{r.reason}”
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  );
}
