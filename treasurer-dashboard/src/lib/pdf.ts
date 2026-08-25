import { jsPDF } from "jspdf";
import autoTable from "jspdf-autotable";
import { formatKes } from "./utils";
import type { ContributionRow, Metrics } from "./analytics";

const GREEN: [number, number, number] = [18, 183, 106];
const INK: [number, number, number] = [15, 23, 41];
const MUTED: [number, number, number] = [102, 112, 133];

function header(doc: jsPDF, title: string, church: string): number {
  doc.setFillColor(...GREEN);
  doc.roundedRect(40, 36, 22, 22, 5, 5, "F");
  doc.setTextColor(...INK);
  doc.setFont("helvetica", "bold");
  doc.setFontSize(16);
  doc.text("Bahasha", 72, 46);
  doc.setFont("helvetica", "normal");
  doc.setFontSize(10);
  doc.setTextColor(...MUTED);
  doc.text(title, 72, 60);
  doc.setFontSize(10);
  doc.setTextColor(...INK);
  doc.text(church, doc.internal.pageSize.getWidth() - 40, 46, { align: "right" });
  doc.setTextColor(...MUTED);
  doc.text(new Date().toLocaleString(), doc.internal.pageSize.getWidth() - 40, 60, { align: "right" });
  doc.setDrawColor(231, 235, 239);
  doc.line(40, 74, doc.internal.pageSize.getWidth() - 40, 74);
  return 92;
}

function fileStamp(): string {
  return new Date().toISOString().slice(0, 10);
}

/** A full giving-report overview: KPIs, category breakdown, recent gifts. */
export function exportReportPdf(metrics: Metrics, church: string): void {
  const doc = new jsPDF({ unit: "pt", format: "a4" });
  let y = header(doc, "Giving report", church);

  const kpis: [string, string][] = [
    ["Total received", formatKes(metrics.totalGiven)],
    ["This month", formatKes(metrics.totals.month)],
    ["This week", formatKes(metrics.totals.week)],
    ["Settled gifts", `${metrics.completedCount} of ${metrics.contributionCount}`],
    ["From members", formatKes(metrics.membership.member)],
    ["From visitors", formatKes(metrics.membership.visitor)],
  ];
  const colW = (doc.internal.pageSize.getWidth() - 80) / 3;
  kpis.forEach((k, i) => {
    const col = i % 3;
    const row = Math.floor(i / 3);
    const x = 40 + col * colW;
    const ky = y + row * 60;
    doc.setDrawColor(231, 235, 239);
    doc.roundedRect(x, ky, colW - 12, 48, 6, 6, "S");
    doc.setFontSize(8);
    doc.setTextColor(...MUTED);
    doc.text(k[0].toUpperCase(), x + 12, ky + 18);
    doc.setFont("helvetica", "bold");
    doc.setFontSize(13);
    doc.setTextColor(...INK);
    doc.text(k[1], x + 12, ky + 36);
    doc.setFont("helvetica", "normal");
  });
  y += 60 * Math.ceil(kpis.length / 3) + 16;

  autoTable(doc, {
    startY: y,
    head: [["Category", "Amount"]],
    body: metrics.byCategory.map((c) => [c.name, formatKes(c.amount)]),
    theme: "striped",
    headStyles: { fillColor: GREEN, textColor: 255, fontStyle: "bold" },
    styles: { fontSize: 9, cellPadding: 6, textColor: INK },
    columnStyles: { 1: { halign: "right" } },
    margin: { left: 40, right: 40 },
  });

  const afterCats = (doc as unknown as { lastAutoTable: { finalY: number } }).lastAutoTable.finalY;
  autoTable(doc, {
    startY: afterCats + 20,
    head: [["Date", "Giver", "Status", "Amount"]],
    body: metrics.recent.map((r) => [
      new Date(r.received_at).toLocaleDateString(),
      r.visibility_snapshot === "secret" ? r.giver_pseudonym ?? "Anonymous" : r.giver_name,
      r.status,
      formatKes(r.total_amount),
    ]),
    theme: "grid",
    headStyles: { fillColor: INK, textColor: 255, fontStyle: "bold" },
    styles: { fontSize: 9, cellPadding: 6, textColor: INK },
    columnStyles: { 3: { halign: "right" } },
    margin: { left: 40, right: 40 },
  });

  doc.save(`bahasha-report-${fileStamp()}.pdf`);
}

/** A single-contribution invoice / receipt. */
export function exportInvoicePdf(row: ContributionRow, church: string): void {
  const doc = new jsPDF({ unit: "pt", format: "a4" });
  let y = header(doc, "Contribution receipt", church);

  doc.setFontSize(10);
  doc.setTextColor(...MUTED);
  doc.text(`Reference: ${row.id.slice(0, 8).toUpperCase()}`, 40, y);
  doc.text(`Date: ${new Date(row.received_at).toLocaleString()}`, 40, y + 16);
  doc.text(
    `Giver: ${row.visibility_snapshot === "secret" ? row.giver_pseudonym ?? "Anonymous giver" : row.giver_name}`,
    40,
    y + 32,
  );
  doc.text(`Status: ${row.status}`, 40, y + 48);
  y += 68;

  autoTable(doc, {
    startY: y,
    head: [["Giving type", "Amount"]],
    body: row.categories.map((c) => [c.name, formatKes(c.amount)]),
    foot: [["Total", formatKes(row.total_amount)]],
    theme: "striped",
    headStyles: { fillColor: GREEN, textColor: 255, fontStyle: "bold" },
    footStyles: { fillColor: [231, 248, 239], textColor: INK, fontStyle: "bold" },
    styles: { fontSize: 10, cellPadding: 7, textColor: INK },
    columnStyles: { 1: { halign: "right" } },
    margin: { left: 40, right: 40 },
  });

  doc.setFontSize(8);
  doc.setTextColor(...MUTED);
  doc.text(
    "Bahasha — offline-first church giving.  © 2026 Bahasha.",
    40,
    doc.internal.pageSize.getHeight() - 40,
  );
  doc.save(`bahasha-receipt-${row.id.slice(0, 8)}.pdf`);
}
