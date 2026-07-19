"use client";

import { useMemo } from "react";
import {
  CalendarDays,
  CalendarRange,
  CalendarClock,
  Wallet,
  Download,
  Moon,
  Sun,
  EyeOff,
  Users,
  LogIn,
  LogOut,
} from "lucide-react";
import { useRouter } from "next/navigation";
import { useContributions, downloadCsv } from "@/lib/use-contributions";
import { useAuth, signOut } from "@/lib/use-auth";
import { useIsSuperAdmin } from "@/lib/use-admin";
import { Shield } from "lucide-react";
import { computeMetrics } from "@/lib/analytics";
import { formatKes, formatNumber } from "@/lib/utils";
import { StatCard } from "@/components/dashboard/stat-card";
import {
  CategoryChart,
  MembershipChart,
  TrendChart,
  VisibilityChart,
} from "@/components/dashboard/charts";
import { TransactionsTable } from "@/components/dashboard/transactions-table";
import { Badge } from "@/components/ui/badge";
import { useTheme } from "@/components/theme-provider";

export default function DashboardPage() {
  const { rows, source, loading } = useContributions();
  const { theme, toggle } = useTheme();
  const { email, configured } = useAuth();
  const { isSuperAdmin } = useIsSuperAdmin();
  const router = useRouter();
  const metrics = useMemo(() => computeMetrics(rows), [rows]);

  const anonShare =
    metrics.visibility.open + metrics.visibility.secret > 0
      ? Math.round(
          (metrics.visibility.secret / (metrics.visibility.open + metrics.visibility.secret)) * 100,
        )
      : 0;

  return (
    <div className="min-h-dvh">
      {/* Top bar */}
      <header className="sticky top-0 z-10 border-b bg-background/80 backdrop-blur">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
          <div className="flex items-center gap-3">
            <div className="grid size-9 place-items-center rounded-xl bg-indigo text-white">
              <Wallet className="size-5" />
            </div>
            <div>
              <h1 className="text-lg font-semibold leading-tight">Bahasha Treasurer</h1>
              <p className="text-xs text-muted-foreground">Giving analytics & reports</p>
            </div>
          </div>
          <div className="flex items-center gap-2">
            {source === "demo" ? <Badge variant="warning">Demo data</Badge> : <Badge variant="success">Live</Badge>}
            {isSuperAdmin ? (
              <button
                onClick={() => router.push("/admin")}
                className="inline-flex items-center gap-2 rounded-lg border border-indigo/30 bg-indigo/5 px-3 py-2 text-sm font-medium text-indigo hover:bg-indigo/10 dark:text-accent-violet"
              >
                <Shield className="size-4" /> Super Admin
              </button>
            ) : null}
            {email ? (
              <span className="hidden text-sm text-muted-foreground sm:inline">{email}</span>
            ) : null}
            <button
              onClick={() => downloadCsv(rows)}
              className="inline-flex items-center gap-2 rounded-lg border px-3 py-2 text-sm hover:bg-muted"
            >
              <Download className="size-4" /> CSV
            </button>
            <button
              onClick={toggle}
              aria-label="Toggle theme"
              className="grid size-9 place-items-center rounded-lg border hover:bg-muted"
            >
              {theme === "dark" ? <Sun className="size-4" /> : <Moon className="size-4" />}
            </button>
            {email ? (
              <button
                onClick={async () => {
                  await signOut();
                  router.refresh();
                }}
                aria-label="Sign out"
                className="grid size-9 place-items-center rounded-lg border hover:bg-muted"
                title="Sign out"
              >
                <LogOut className="size-4" />
              </button>
            ) : configured ? (
              <button
                onClick={() => router.push("/login")}
                className="inline-flex items-center gap-2 rounded-lg bg-indigo px-3 py-2 text-sm font-medium text-white hover:opacity-90"
              >
                <LogIn className="size-4" /> Sign in
              </button>
            ) : null}
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-7xl px-6 py-6">
        {source === "demo" ? (
          <div className="mb-6 rounded-xl border border-warning/30 bg-warning/10 px-4 py-3 text-sm">
            Showing <strong>demo data</strong>. Sign a treasurer in and populate the schema to see
            live giving. Secret givers will appear as pseudonyms — their identity never reaches this
            dashboard.
          </div>
        ) : null}

        {/* Headline period totals */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            index={0}
            label="Today"
            value={formatKes(metrics.totals.today)}
            icon={CalendarDays}
            accent="green"
          />
          <StatCard
            index={1}
            label="This week"
            value={formatKes(metrics.totals.week)}
            icon={CalendarRange}
            accent="cyan"
          />
          <StatCard
            index={2}
            label="This month"
            value={formatKes(metrics.totals.month)}
            icon={CalendarClock}
            accent="violet"
          />
          <StatCard
            index={3}
            label="This year"
            value={formatKes(metrics.totals.year)}
            icon={Wallet}
            accent="indigo"
          />
        </div>

        {/* Secondary stats */}
        <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            index={4}
            label="Total received"
            value={formatKes(metrics.totalGiven)}
            sub={`${formatNumber(metrics.completedCount)} settled of ${formatNumber(metrics.contributionCount)}`}
            icon={Wallet}
            accent="indigo"
          />
          <StatCard
            index={5}
            label="Anonymous giving"
            value={`${anonShare}%`}
            sub={formatKes(metrics.visibility.secret)}
            icon={EyeOff}
            accent="violet"
          />
          <StatCard
            index={6}
            label="From members"
            value={formatKes(metrics.membership.member)}
            icon={Users}
            accent="green"
          />
          <StatCard
            index={7}
            label="From visitors"
            value={formatKes(metrics.membership.visitor)}
            icon={Users}
            accent="cyan"
          />
        </div>

        {/* Charts */}
        <div className="mt-6 grid grid-cols-1 gap-4 lg:grid-cols-2">
          <TrendChart metrics={metrics} />
          <CategoryChart metrics={metrics} />
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:col-span-1">
            <MembershipChart metrics={metrics} />
            <VisibilityChart metrics={metrics} />
          </div>
        </div>

        {/* Transactions */}
        <div className="mt-6 grid grid-cols-1 gap-4">
          <TransactionsTable rows={metrics.recent.length ? rows : []} />
        </div>

        {loading ? (
          <p className="mt-6 text-center text-sm text-muted-foreground">Loading…</p>
        ) : null}
      </main>
    </div>
  );
}
