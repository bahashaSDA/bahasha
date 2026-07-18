/**
 * Analytics domain.
 *
 * Pure aggregation over contribution rows, deliberately separated from data
 * fetching so it is unit-testable and identical whether the rows come from the
 * live masking views or the demo set. The row shape mirrors
 * `v_church_contributions` (0007_rls.sql): secret givers already arrive masked
 * as a pseudonym with no name/phone, so the dashboard never has to mask
 * anything itself — the database did it.
 */

import {
  startOfDay,
  startOfWeek,
  startOfMonth,
  startOfYear,
  subDays,
  format,
} from "date-fns";

export type Visibility = "open" | "secret";
export type MembershipStatus = "member" | "visitor" | "other_church_member" | null;
export type ContributionStatus =
  | "pending"
  | "processing"
  | "completed"
  | "failed"
  | "cancelled"
  | "expired";

/** One masked contribution as returned by v_church_contributions. */
export interface ContributionRow {
  id: string;
  total_amount: number;
  status: ContributionStatus;
  visibility_snapshot: Visibility;
  received_at: string; // ISO
  giver_name: string; // "Anonymous giver" when secret
  giver_pseudonym: string | null; // "G-XXXX" when secret, else null
  membership_status: MembershipStatus; // null when secret
  categories: { code: string; name: string; amount: number }[];
}

export interface PeriodTotals {
  today: number;
  week: number;
  month: number;
  year: number;
}

export interface Metrics {
  totals: PeriodTotals;
  totalGiven: number;
  contributionCount: number;
  completedCount: number;
  /** Sum by category, sorted desc. */
  byCategory: { code: string; name: string; amount: number }[];
  /** Member vs visitor split (completed, non-secret rows carry membership). */
  membership: { member: number; visitor: number; other: number; unknown: number };
  /** Open vs secret giving split. */
  visibility: { open: number; secret: number };
  /** Daily totals for the last 30 days, for the trend chart. */
  trend: { date: string; label: string; amount: number }[];
  /** Most recent rows (already masked). */
  recent: ContributionRow[];
}

/** Only settled money counts toward financial totals. */
function isSettled(r: ContributionRow): boolean {
  return r.status === "completed";
}

export function computeMetrics(rows: ContributionRow[], now = new Date()): Metrics {
  const settled = rows.filter(isSettled);

  const dayStart = startOfDay(now);
  const weekStart = startOfWeek(now, { weekStartsOn: 1 });
  const monthStart = startOfMonth(now);
  const yearStart = startOfYear(now);

  const totals: PeriodTotals = { today: 0, week: 0, month: 0, year: 0 };
  const categoryMap = new Map<string, { name: string; amount: number }>();
  const membership = { member: 0, visitor: 0, other: 0, unknown: 0 };
  const visibility = { open: 0, secret: 0 };

  for (const r of settled) {
    const at = new Date(r.received_at);
    if (at >= dayStart) totals.today += r.total_amount;
    if (at >= weekStart) totals.week += r.total_amount;
    if (at >= monthStart) totals.month += r.total_amount;
    if (at >= yearStart) totals.year += r.total_amount;

    for (const c of r.categories) {
      const cur = categoryMap.get(c.code) ?? { name: c.name, amount: 0 };
      cur.amount += c.amount;
      categoryMap.set(c.code, cur);
    }

    if (r.visibility_snapshot === "secret") visibility.secret += r.total_amount;
    else visibility.open += r.total_amount;

    switch (r.membership_status) {
      case "member":
        membership.member += r.total_amount;
        break;
      case "visitor":
        membership.visitor += r.total_amount;
        break;
      case "other_church_member":
        membership.other += r.total_amount;
        break;
      default:
        membership.unknown += r.total_amount;
    }
  }

  const byCategory = [...categoryMap.entries()]
    .map(([code, v]) => ({ code, name: v.name, amount: v.amount }))
    .sort((a, b) => b.amount - a.amount);

  // 30-day daily trend.
  const trendMap = new Map<string, number>();
  for (let i = 29; i >= 0; i--) {
    const d = startOfDay(subDays(now, i));
    trendMap.set(format(d, "yyyy-MM-dd"), 0);
  }
  for (const r of settled) {
    const key = format(startOfDay(new Date(r.received_at)), "yyyy-MM-dd");
    if (trendMap.has(key)) trendMap.set(key, trendMap.get(key)! + r.total_amount);
  }
  const trend = [...trendMap.entries()].map(([date, amount]) => ({
    date,
    label: format(new Date(date), "MMM d"),
    amount,
  }));

  const recent = [...rows]
    .sort((a, b) => +new Date(b.received_at) - +new Date(a.received_at))
    .slice(0, 12);

  return {
    totals,
    totalGiven: settled.reduce((s, r) => s + r.total_amount, 0),
    contributionCount: rows.length,
    completedCount: settled.length,
    byCategory,
    membership,
    visibility,
    trend,
    recent,
  };
}

/** Category display names + codes, mirroring the backend seed. */
const CATEGORY_NAMES: Record<string, string> = {
  tithe: "God's Tithe",
  combined_offering: "Combined Offering",
  local_church_budget: "Local Church Budget",
  church_building: "Church Building",
  church_evangelism: "Church Evangelism",
  conference_evangelism: "Conference Evangelism",
  camp_meeting_offering: "Camp Meeting Offering",
  thanksgiving: "Thanksgiving",
  welfare: "Welfare",
  station_fund: "Station Fund",
  others: "Others",
};

/**
 * A realistic demo dataset so the dashboard is fully alive before the live
 * schema and real giving exist. Clearly labelled as demo in the UI; replaced
 * automatically by live data once Supabase is configured and populated.
 */
export function demoRows(now = new Date()): ContributionRow[] {
  const codes = Object.keys(CATEGORY_NAMES);
  const rows: ContributionRow[] = [];
  // Deterministic pseudo-random so the demo is stable across renders.
  let seed = 42;
  const rand = () => {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    return seed / 0x7fffffff;
  };

  for (let i = 0; i < 260; i++) {
    const daysAgo = Math.floor(rand() * 90);
    const received = subDays(now, daysAgo);
    const secret = rand() < 0.22;
    const nCats = 1 + Math.floor(rand() * 3);
    const chosen = new Set<string>();
    while (chosen.size < nCats) chosen.add(codes[Math.floor(rand() * codes.length)]);
    const categories = [...chosen].map((code) => ({
      code,
      name: CATEGORY_NAMES[code],
      amount: [100, 200, 300, 500, 1000, 1500, 2000][Math.floor(rand() * 7)],
    }));
    const total = categories.reduce((s, c) => s + c.amount, 0);
    const membershipRoll = rand();
    const membership: MembershipStatus = secret
      ? null
      : membershipRoll < 0.7
      ? "member"
      : membershipRoll < 0.9
      ? "visitor"
      : "other_church_member";
    const statusRoll = rand();
    const status: ContributionStatus =
      statusRoll < 0.86 ? "completed" : statusRoll < 0.94 ? "failed" : "cancelled";

    rows.push({
      id: `demo-${i}`,
      total_amount: total,
      status,
      visibility_snapshot: secret ? "secret" : "open",
      received_at: received.toISOString(),
      giver_name: secret ? "Anonymous giver" : demoName(rand),
      giver_pseudonym: secret ? `G-${(0x1000 + i).toString(16).toUpperCase()}` : null,
      membership_status: membership,
      categories,
    });
  }
  return rows;
}

function demoName(rand: () => number): string {
  const first = ["Grace", "Peter", "Mary", "John", "Faith", "Samuel", "Esther", "David", "Ruth", "Daniel"];
  const last = ["Wanjiru", "Otieno", "Mwangi", "Achieng", "Kamau", "Njoroge", "Auma", "Kiptoo", "Chebet", "Mutua"];
  return `${first[Math.floor(rand() * first.length)]} ${last[Math.floor(rand() * last.length)]}`;
}
