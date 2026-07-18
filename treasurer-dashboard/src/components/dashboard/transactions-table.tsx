"use client";

import { useMemo, useState } from "react";
import { format } from "date-fns";
import { Search } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { formatKes } from "@/lib/utils";
import type { ContributionRow, ContributionStatus } from "@/lib/analytics";

const statusVariant: Record<ContributionStatus, "success" | "danger" | "warning" | "muted"> = {
  completed: "success",
  failed: "danger",
  cancelled: "warning",
  pending: "muted",
  processing: "muted",
  expired: "muted",
};

/**
 * Recent transactions, searchable and paginated client-side. Secret givers show
 * their pseudonym and a "Secret" badge — the row never contains their real
 * identity because the masking view stripped it before it reached the browser.
 */
export function TransactionsTable({ rows }: { rows: ContributionRow[] }) {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(0);
  const pageSize = 8;

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return rows;
    return rows.filter((r) => {
      const who = (r.giver_pseudonym ?? r.giver_name).toLowerCase();
      const cats = r.categories.map((c) => c.name.toLowerCase()).join(" ");
      return who.includes(q) || cats.includes(q);
    });
  }, [rows, query]);

  const pageCount = Math.max(1, Math.ceil(filtered.length / pageSize));
  const current = Math.min(page, pageCount - 1);
  const shown = filtered.slice(current * pageSize, current * pageSize + pageSize);

  return (
    <Card className="col-span-full">
      <CardHeader className="flex-row items-center justify-between">
        <CardTitle>Recent transactions</CardTitle>
        <div className="relative w-56">
          <Search className="absolute left-2.5 top-2.5 size-4 text-muted-foreground" />
          <input
            value={query}
            onChange={(e) => {
              setQuery(e.target.value);
              setPage(0);
            }}
            placeholder="Search giver or category"
            className="w-full rounded-lg border bg-background py-2 pl-8 pr-3 text-sm outline-none focus:ring-2 focus:ring-ring"
          />
        </div>
      </CardHeader>
      <CardContent className="pt-0">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b text-left text-xs uppercase text-muted-foreground">
                <th className="py-2.5 pr-4 font-medium">Giver</th>
                <th className="py-2.5 pr-4 font-medium">Categories</th>
                <th className="py-2.5 pr-4 text-right font-medium">Amount</th>
                <th className="py-2.5 pr-4 font-medium">Status</th>
                <th className="py-2.5 font-medium">When</th>
              </tr>
            </thead>
            <tbody>
              {shown.map((r) => (
                <tr key={r.id} className="border-b last:border-0">
                  <td className="py-3 pr-4">
                    <div className="flex items-center gap-2">
                      <span className="font-medium">
                        {r.visibility_snapshot === "secret" ? r.giver_pseudonym : r.giver_name}
                      </span>
                      {r.visibility_snapshot === "secret" ? (
                        <Badge variant="violet">Secret</Badge>
                      ) : null}
                    </div>
                  </td>
                  <td className="py-3 pr-4 text-muted-foreground">
                    {r.categories.map((c) => c.name).join(", ")}
                  </td>
                  <td className="py-3 pr-4 text-right font-medium tabular-nums">
                    {formatKes(r.total_amount)}
                  </td>
                  <td className="py-3 pr-4">
                    <Badge variant={statusVariant[r.status]}>{r.status}</Badge>
                  </td>
                  <td className="py-3 text-muted-foreground">
                    {format(new Date(r.received_at), "MMM d, HH:mm")}
                  </td>
                </tr>
              ))}
              {shown.length === 0 ? (
                <tr>
                  <td colSpan={5} className="py-8 text-center text-muted-foreground">
                    No transactions match “{query}”.
                  </td>
                </tr>
              ) : null}
            </tbody>
          </table>
        </div>

        <div className="mt-4 flex items-center justify-between text-sm text-muted-foreground">
          <span>
            {filtered.length} transaction{filtered.length === 1 ? "" : "s"}
          </span>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={current === 0}
              className="rounded-lg border px-3 py-1.5 disabled:opacity-40"
            >
              Previous
            </button>
            <span>
              {current + 1} / {pageCount}
            </span>
            <button
              onClick={() => setPage((p) => Math.min(pageCount - 1, p + 1))}
              disabled={current >= pageCount - 1}
              className="rounded-lg border px-3 py-1.5 disabled:opacity-40"
            >
              Next
            </button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
