import * as React from "react";
import { cn } from "@/lib/utils";

type Variant = "default" | "success" | "danger" | "warning" | "muted" | "violet";

const styles: Record<Variant, string> = {
  default: "bg-indigo/10 text-indigo dark:bg-indigo/30 dark:text-accent-violet",
  success: "bg-success/12 text-success",
  danger: "bg-danger/12 text-danger",
  warning: "bg-warning/15 text-warning",
  muted: "bg-muted text-muted-foreground",
  violet: "bg-accent-violet/20 text-indigo dark:text-accent-violet",
};

export function Badge({
  variant = "default",
  className,
  ...props
}: React.HTMLAttributes<HTMLSpanElement> & { variant?: Variant }) {
  return (
    <span
      className={cn(
        "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium",
        styles[variant],
        className,
      )}
      {...props}
    />
  );
}
