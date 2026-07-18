"use client";

import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatKes } from "@/lib/utils";
import type { Metrics } from "@/lib/analytics";

// The Bahasha accent palette, reused across every chart so series colours are
// consistent with the mobile app.
const PALETTE = ["#231F4F", "#89D385", "#6CD1F0", "#A1A1F7", "#2f9e44", "#e8a13a"];

function MoneyTooltip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-lg border bg-card px-3 py-2 text-sm shadow-md">
      <p className="font-medium">{label ?? payload[0].name}</p>
      <p className="text-muted-foreground">{formatKes(payload[0].value as number)}</p>
    </div>
  );
}

/** 30-day giving trend as a smooth filled area. */
export function TrendChart({ metrics }: { metrics: Metrics }) {
  return (
    <Card className="col-span-full">
      <CardHeader>
        <CardTitle>Giving trend — last 30 days</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-64 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={metrics.trend} margin={{ top: 8, right: 8, left: 8, bottom: 0 }}>
              <defs>
                <linearGradient id="trendFill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#89D385" stopOpacity={0.5} />
                  <stop offset="100%" stopColor="#89D385" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="label" tickLine={false} axisLine={false} minTickGap={28} fontSize={12} />
              <YAxis
                tickFormatter={(v) => formatKes(v as number, { compact: true })}
                tickLine={false}
                axisLine={false}
                width={56}
                fontSize={12}
              />
              <Tooltip content={<MoneyTooltip />} />
              <Area
                type="monotone"
                dataKey="amount"
                stroke="#2f7d3a"
                strokeWidth={2}
                fill="url(#trendFill)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}

/** Top categories by amount. */
export function CategoryChart({ metrics }: { metrics: Metrics }) {
  const data = metrics.byCategory.slice(0, 8);
  return (
    <Card>
      <CardHeader>
        <CardTitle>Top categories</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-72 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={data} layout="vertical" margin={{ left: 8, right: 16 }}>
              <XAxis type="number" hide />
              <YAxis
                type="category"
                dataKey="name"
                width={130}
                tickLine={false}
                axisLine={false}
                fontSize={12}
              />
              <Tooltip content={<MoneyTooltip />} cursor={{ fill: "var(--color-muted)" }} />
              <Bar dataKey="amount" radius={[0, 6, 6, 0]}>
                {data.map((_, i) => (
                  <Cell key={i} fill={PALETTE[i % PALETTE.length]} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}

function Donut({
  title,
  data,
}: {
  title: string;
  data: { name: string; value: number; color: string }[];
}) {
  const total = data.reduce((s, d) => s + d.value, 0);
  return (
    <Card>
      <CardHeader>
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex items-center gap-4">
          <div className="h-40 w-40 shrink-0">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={data}
                  dataKey="value"
                  nameKey="name"
                  innerRadius={44}
                  outerRadius={72}
                  paddingAngle={2}
                  strokeWidth={0}
                >
                  {data.map((d, i) => (
                    <Cell key={i} fill={d.color} />
                  ))}
                </Pie>
                <Tooltip content={<MoneyTooltip />} />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <ul className="flex-1 space-y-2 text-sm">
            {data.map((d) => (
              <li key={d.name} className="flex items-center justify-between gap-2">
                <span className="flex items-center gap-2">
                  <span className="size-2.5 rounded-full" style={{ background: d.color }} />
                  {d.name}
                </span>
                <span className="text-muted-foreground">
                  {total ? Math.round((d.value / total) * 100) : 0}%
                </span>
              </li>
            ))}
          </ul>
        </div>
      </CardContent>
    </Card>
  );
}

export function MembershipChart({ metrics }: { metrics: Metrics }) {
  const m = metrics.membership;
  return (
    <Donut
      title="Member vs visitor"
      data={[
        { name: "Members", value: m.member, color: "#231F4F" },
        { name: "Visitors", value: m.visitor, color: "#6CD1F0" },
        { name: "Other church", value: m.other, color: "#A1A1F7" },
        { name: "Anonymous", value: m.unknown, color: "#89D385" },
      ]}
    />
  );
}

export function VisibilityChart({ metrics }: { metrics: Metrics }) {
  const v = metrics.visibility;
  return (
    <Donut
      title="Open vs secret giving"
      data={[
        { name: "Open giving", value: v.open, color: "#89D385" },
        { name: "Secret giving", value: v.secret, color: "#231F4F" },
      ]}
    />
  );
}
