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

        // Read through the SECURITY DEFINER RPC, not the view: on Supabase a
        // plain view cannot join public.users (RLS), so the masked giver
        // identity must come from a definer function. It already scopes rows to
        // this treasurer's church and masks secret givers to a pseudonym.
        const { data, error } = await supabase.rpc("get_church_contributions");

        if (error) throw error;

        const contribs = (data ?? []) as Omit<ContributionRow, "categories">[];

        // Hydrate the per-category allocation lines so the category charts show
        // real figures. RLS lets a treasurer read allocations for their own
        // church's contributions (allocations_read_via_parent policy).
        const ids = contribs.map((c) => c.id);
        const byContribution = new Map<string, { code: string; name: string; amount: number }[]>();
        if (ids.length) {
          const { data: allocs } = await supabase
            .from("contribution_allocations")
            .select("contribution_id, amount, contribution_categories(code, name)")
            .in("contribution_id", ids);
          for (const a of (allocs ?? []) as unknown as Array<{
            contribution_id: string;
            amount: number;
            // Supabase may return the joined row as an object or a single-element array.
            contribution_categories: { code: string; name: string } | { code: string; name: string }[] | null;
          }>) {
            const cat = Array.isArray(a.contribution_categories)
              ? a.contribution_categories[0]
              : a.contribution_categories;
            const list = byContribution.get(a.contribution_id) ?? [];
            list.push({ code: cat?.code ?? "", name: cat?.name ?? "", amount: Number(a.amount) });
            byContribution.set(a.contribution_id, list);
          }
        }

        const rows: ContributionRow[] = contribs.map((r) => ({
          ...r,
          categories: byContribution.get(r.id) ?? [],
        }));

        // Signed in ⇒ always LIVE, even with zero rows. A real treasurer with no
        // giving yet sees an honest empty dashboard, never fabricated demo data.
        if (!cancelled) setState({ rows, source: "live", loading: false, error: null });
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
