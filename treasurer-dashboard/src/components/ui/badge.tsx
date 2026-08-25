import * as React from "react";
import { cn } from "@/lib/utils";

type Variant = "default" | "success" | "danger" | "warning" | "muted" | "violet";

const styles: Record<Variant, string> = {
  default: "bg-primary-tint text-primary-strong",
  success: "bg-primary-tint text-primary-strong",
  danger: "bg-danger/12 text-danger",
  warning: "bg-warning/15 text-warning",
  muted: "bg-muted text-muted-foreground",
  violet: "bg-c3/12 text-c3",
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
