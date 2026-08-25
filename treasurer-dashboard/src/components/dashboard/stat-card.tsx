"use client";

import type { LucideIcon } from "lucide-react";

type Accent = "green" | "blue" | "violet" | "amber" | "slate";

const ACCENT: Record<Accent, { icon: string; ring: string }> = {
  green: { icon: "text-primary", ring: "bg-primary-tint" },
  blue: { icon: "text-c2", ring: "bg-c2/10" },
  violet: { icon: "text-c3", ring: "bg-c3/10" },
  amber: { icon: "text-c4", ring: "bg-c4/10" },
  slate: { icon: "text-foreground", ring: "bg-muted" },
};

interface StatCardProps {
  label: string;
  value: string;
  sub?: string;
  icon: LucideIcon;
  accent?: Accent;
  /** Optional trend chip, e.g. "+12%". */
  trend?: { value: string; up: boolean };
}

/**
 * A premium KPI tile: a tinted icon, an uppercase label, a large tabular value,
 * an optional subtext and a coloured trend chip. Fixed heights and tabular
 * figures keep a row of them perfectly aligned.
 */
export function StatCard({ label, value, sub, icon: Icon, accent = "green", trend }: StatCardProps) {
  const a = ACCENT[accent];
  return (
    <div className="card-surface flex flex-col gap-4 p-5">
      <div className="flex items-center justify-between">
        <div className={`grid size-10 place-items-center rounded-xl ${a.ring}`}>
          <Icon className={`size-5 ${a.icon}`} />
        </div>
        {trend ? (
          <span
            className={`rounded-full px-2 py-0.5 text-xs font-medium ${
              trend.up ? "bg-primary-tint text-primary-strong" : "bg-danger/10 text-danger"
            }`}
          >
            {trend.up ? "▲" : "▼"} {trend.value}
          </span>
        ) : null}
      </div>
      <div>
        <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">{label}</p>
        <p className="mt-1 text-2xl font-semibold tracking-tight tabular-nums">{value}</p>
        {sub ? <p className="mt-1 text-xs text-muted-foreground">{sub}</p> : null}
      </div>
    </div>
  );
}
