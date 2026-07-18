"use client";

import { motion } from "framer-motion";
import { type LucideIcon } from "lucide-react";
import { Card } from "@/components/ui/card";
import { cn } from "@/lib/utils";

/**
 * A headline metric tile: label, value, an accent icon, and an optional
 * sub-line. Animates in on mount for the "premium" feel, staggered by [index].
 */
export function StatCard({
  label,
  value,
  sub,
  icon: Icon,
  accent = "indigo",
  index = 0,
}: {
  label: string;
  value: string;
  sub?: string;
  icon: LucideIcon;
  accent?: "indigo" | "green" | "cyan" | "violet";
  index?: number;
}) {
  const accents: Record<string, string> = {
    indigo: "bg-indigo/10 text-indigo dark:text-accent-violet",
    green: "bg-accent-green/20 text-[#2f7d3a] dark:text-accent-green",
    cyan: "bg-accent-cyan/25 text-[#1c7fa0] dark:text-accent-cyan",
    violet: "bg-accent-violet/25 text-indigo dark:text-accent-violet",
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, delay: index * 0.06, ease: "easeOut" }}
    >
      <Card className="p-5">
        <div className="flex items-start justify-between">
          <div className="min-w-0">
            <p className="text-sm text-muted-foreground">{label}</p>
            <p className="mt-2 text-2xl font-semibold tracking-tight">{value}</p>
            {sub ? <p className="mt-1 text-xs text-muted-foreground">{sub}</p> : null}
          </div>
          <div className={cn("grid size-10 shrink-0 place-items-center rounded-xl", accents[accent])}>
            <Icon className="size-5" />
          </div>
        </div>
      </Card>
    </motion.div>
  );
}
