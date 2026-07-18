"use client";

import { useEffect, useState } from "react";
import { getSupabase, isSupabaseConfigured } from "./supabase";
import { demoRows, type ContributionRow } from "./analytics";

export type DataSource = "live" | "demo";

interface State {
  rows: ContributionRow[];
  source: DataSource;
  loading: boolean;
  error: string | null;
}

/**
 * Loads contributions for the dashboard. Prefers live data from the RLS masking
 * view `v_church_contributions` (which already returns secret givers masked).
 * Falls back to a labelled demo set when Supabase is unconfigured, the user is
 * not signed in, or the schema has no data yet — so the dashboard is always
 * alive, and switches to real data automatically once it exists.
 */
export function useContributions(): State {
  const [state, setState] = useState<State>({
    rows: [],
    source: "demo",
    loading: true,
    error: null,
  });

  useEffect(() => {
    let cancelled = false;

    async function load() {
      if (!isSupabaseConfigured()) {
        if (!cancelled) setState({ rows: demoRows(), source: "demo", loading: false, error: null });
        return;
      }
      try {
        const supabase = getSupabase();
        const { data: session } = await supabase.auth.getSession();
        if (!session.session) {
          // Not signed in: show demo rather than an empty screen.
          if (!cancelled)
            setState({ rows: demoRows(), source: "demo", loading: false, error: null });
          return;
        }

        const { data, error } = await supabase
          .from("v_church_contributions")
          .select(
            "id,total_amount,status,visibility_snapshot,received_at,giver_name,giver_pseudonym,membership_status",
          )
          .order("received_at", { ascending: false })
          .limit(1000);

        if (error) throw error;

        // The view does not embed category lines; fetch allocations per page in
        // production. For the list/analytics here we hydrate categories lazily
        // and tolerate their absence (charts that need them simply show less).
        const rows: ContributionRow[] = (data ?? []).map((r) => ({
          ...(r as Omit<ContributionRow, "categories">),
          categories: [],
        }));

        if (!cancelled)
          setState({
            rows: rows.length ? rows : demoRows(),
            source: rows.length ? "live" : "demo",
            loading: false,
            error: null,
          });
      } catch (e) {
        if (!cancelled)
          setState({
            rows: demoRows(),
            source: "demo",
            loading: false,
            error: e instanceof Error ? e.message : "Failed to load",
          });
      }
    }

    load();
    return () => {
      cancelled = true;
    };
  }, []);

  return state;
}

/** Build a CSV of the given rows and trigger a browser download. */
export function downloadCsv(rows: ContributionRow[]): void {
  const header = ["id", "giver", "amount", "status", "visibility", "received_at", "categories"];
  const lines = rows.map((r) =>
    [
      r.id,
      r.visibility_snapshot === "secret" ? (r.giver_pseudonym ?? "Anonymous") : r.giver_name,
      r.total_amount,
      r.status,
      r.visibility_snapshot,
      r.received_at,
      r.categories.map((c) => `${c.name}:${c.amount}`).join("|"),
    ]
      .map((v) => `"${String(v).replace(/"/g, '""')}"`)
      .join(","),
  );
  const csv = [header.join(","), ...lines].join("\n");
  const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `bahasha-contributions-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
}
