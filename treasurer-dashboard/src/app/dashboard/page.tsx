"use client";

import { useMemo } from "react";
import {
  Wallet,
  CalendarClock,
  Users,
  UserPlus,
  EyeOff,
  Download,
  FileText,
} from "lucide-react";
import { useContributions, downloadCsv } from "@/lib/use-contributions";
import { computeMetrics } from "@/lib/analytics";
import { exportReportPdf } from "@/lib/pdf";
import { formatKes, formatNumber } from "@/lib/utils";
import { Shell } from "@/components/dashboard/shell";
import { StatCard } from "@/components/dashboard/stat-card";
import {
  CategoryChart,
  MembershipChart,
  TrendChart,
  VisibilityChart,
} from "@/components/dashboard/charts";
import { TransactionsTable } from "@/components/dashboard/transactions-table";
import { Badge } from "@/components/ui/badge";

export default function DashboardPage() {
  const { rows, source, loading } = useContributions();
  const metrics = useMemo(() => computeMetrics(rows), [rows]);

  const anonShare =
    metrics.visibility.open + metrics.visibility.secret > 0
      ? Math.round(
          (metrics.visibility.secret / (metrics.visibility.open + metrics.visibility.secret)) * 100,
        )
      : 0;
  const settleRate =
    metrics.contributionCount > 0
      ? Math.round((metrics.completedCount / metrics.contributionCount) * 100)
      : 0;

  return (
    <Shell
      title="Overview"
      subtitle="Giving analytics for your church"
      actions={
        <>
          <span className="no-print mr-1 hidden sm:inline-flex">
            {source === "demo" ? <Badge variant="warning">Demo data</Badge> : <Badge variant="success">Live</Badge>}
          </span>
          <button
            onClick={() => exportReportPdf(metrics, "Your church")}
            className="no-print inline-flex items-center gap-2 rounded-lg bg-primary px-3 py-2 text-sm font-medium text-primary-foreground hover:bg-primary-strong"
          >
            <FileText className="size-4" /> <span className="hidden sm:inline">Report</span> PDF
          </button>
          <button
            onClick={() => downloadCsv(rows)}
            className="no-print inline-flex items-center gap-2 rounded-lg border border-border px-3 py-2 text-sm hover:bg-muted"
          >
            <Download className="size-4" /> CSV
          </button>
        </>
      }
    >
      {source === "demo" ? (
        <div className="mb-6 rounded-xl border border-warning/30 bg-warning/10 px-4 py-3 text-sm">
          Showing <strong>demo data</strong>. Sign in and record giving to see live figures. Secret
          givers always appear as pseudonyms — their identity never reaches this dashboard.
        </div>
      ) : null}

      {/* KPI row */}
      <section className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard
          label="Total received"
          value={formatKes(metrics.totalGiven)}
          sub={`${formatNumber(metrics.completedCount)} settled of ${formatNumber(metrics.contributionCount)}`}
          icon={Wallet}
          accent="green"
          trend={{ value: `${settleRate}% settled`, up: settleRate >= 80 }}
        />
        <StatCard
          label="This month"
          value={formatKes(metrics.totals.month)}
          sub={`This week ${formatKes(metrics.totals.week)}`}
          icon={CalendarClock}
          accent="blue"
        />
        <StatCard
          label="From members"
          value={formatKes(metrics.membership.member)}
          sub={`Visitors ${formatKes(metrics.membership.visitor)}`}
          icon={Users}
          accent="violet"
        />
        <StatCard
          label="Anonymous giving"
          value={`${anonShare}%`}
          sub={formatKes(metrics.visibility.secret)}
          icon={EyeOff}
          accent="amber"
        />
      </section>

      {/* Trend + side donuts */}
      <section className="mt-5 grid grid-cols-1 gap-4 xl:grid-cols-3">
        <div className="xl:col-span-2">
          <TrendChart metrics={metrics} />
        </div>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-1">
          <MembershipChart metrics={metrics} />
          <VisibilityChart metrics={metrics} />
        </div>
      </section>

      {/* Categories + secondary stats */}
      <section className="mt-5 grid grid-cols-1 gap-4 lg:grid-cols-3">
        <div className="lg:col-span-2">
          <CategoryChart metrics={metrics} />
        </div>
        <div className="grid grid-cols-1 gap-4">
          <StatCard
            label="Today"
            value={formatKes(metrics.totals.today)}
            icon={CalendarClock}
            accent="green"
          />
          <StatCard
            label="This year"
            value={formatKes(metrics.totals.year)}
            icon={Wallet}
            accent="slate"
          />
          <StatCard
            label="From visitors"
            value={formatKes(metrics.membership.visitor)}
            icon={UserPlus}
            accent="blue"
          />
        </div>
      </section>

      {/* Transactions */}
      <section className="mt-5">
        <TransactionsTable rows={metrics.recent.length ? rows : []} />
      </section>

      {loading ? (
        <p className="mt-6 text-center text-sm text-muted-foreground">Loading…</p>
      ) : null}

      <footer className="mt-10 border-t border-border pt-6 text-center text-xs text-muted-foreground">
        © 2026 Bahasha
      </footer>
    </Shell>
  );
}
