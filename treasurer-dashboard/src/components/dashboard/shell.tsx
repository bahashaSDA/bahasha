"use client";

import { useState, type ReactNode } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  CreditCard,
  Shield,
  Wallet,
  Moon,
  Sun,
  LogOut,
  LogIn,
  Menu,
  X,
} from "lucide-react";
import { useAuth, signOut } from "@/lib/use-auth";
import { useIsSuperAdmin } from "@/lib/use-admin";
import { useTheme } from "@/components/theme-provider";

interface ShellProps {
  title: string;
  subtitle?: string;
  actions?: ReactNode;
  children: ReactNode;
}

/**
 * The premium dashboard chrome: a deep-slate icon+label sidebar, a clean top bar
 * with the page title and account controls, and a roomy content canvas. Shared
 * by every signed-in page so the product reads as one polished platform.
 */
export function Shell({ title, subtitle, actions, children }: ShellProps) {
  const pathname = usePathname();
  const router = useRouter();
  const { email, configured } = useAuth();
  const { isSuperAdmin } = useIsSuperAdmin();
  const { theme, toggle } = useTheme();
  const [open, setOpen] = useState(false);

  const nav = [
    { href: "/dashboard", label: "Overview", icon: LayoutDashboard },
    { href: "/payments", label: "Payments & Hub", icon: CreditCard },
    ...(isSuperAdmin ? [{ href: "/admin", label: "Super Admin", icon: Shield }] : []),
  ];

  return (
    <div className="min-h-dvh lg:grid lg:grid-cols-[248px_1fr]">
      {/* Sidebar */}
      <aside
        className={`fixed inset-y-0 left-0 z-40 w-[248px] transform bg-brand text-brand-foreground transition-transform lg:static lg:translate-x-0 ${
          open ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div className="flex h-full flex-col">
          <div className="flex items-center gap-3 px-6 py-6">
            <div className="grid size-9 place-items-center rounded-xl bg-primary text-primary-foreground">
              <Wallet className="size-5" />
            </div>
            <div className="leading-tight">
              <p className="text-[15px] font-semibold">Bahasha</p>
              <p className="text-xs text-brand-muted">Treasury</p>
            </div>
            <button
              onClick={() => setOpen(false)}
              className="ml-auto grid size-8 place-items-center rounded-lg text-brand-muted hover:bg-white/5 lg:hidden"
              aria-label="Close menu"
            >
              <X className="size-5" />
            </button>
          </div>

          <nav className="mt-2 flex flex-1 flex-col gap-1 px-3">
            {nav.map((item) => {
              const active = pathname === item.href;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={() => setOpen(false)}
                  className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm transition ${
                    active
                      ? "bg-white/10 font-medium text-white"
                      : "text-brand-muted hover:bg-white/5 hover:text-white"
                  }`}
                >
                  <item.icon className="size-[18px]" />
                  {item.label}
                  {active ? <span className="ml-auto size-1.5 rounded-full bg-primary" /> : null}
                </Link>
              );
            })}
          </nav>

          <div className="border-t border-white/10 px-3 py-4">
            {email ? (
              <div className="flex items-center gap-3 rounded-xl px-3 py-2">
                <div className="grid size-8 place-items-center rounded-full bg-white/10 text-xs font-semibold uppercase text-white">
                  {email.slice(0, 2)}
                </div>
                <span className="truncate text-xs text-brand-muted">{email}</span>
                <button
                  onClick={async () => {
                    await signOut();
                    router.refresh();
                  }}
                  className="ml-auto grid size-8 place-items-center rounded-lg text-brand-muted hover:bg-white/5 hover:text-white"
                  title="Sign out"
                >
                  <LogOut className="size-4" />
                </button>
              </div>
            ) : configured ? (
              <button
                onClick={() => router.push("/login")}
                className="flex w-full items-center gap-2 rounded-xl bg-white/10 px-3 py-2.5 text-sm font-medium text-white hover:bg-white/15"
              >
                <LogIn className="size-4" /> Sign in
              </button>
            ) : null}
          </div>
        </div>
      </aside>

      {/* Backdrop for mobile drawer */}
      {open ? (
        <div className="fixed inset-0 z-30 bg-black/40 lg:hidden" onClick={() => setOpen(false)} />
      ) : null}

      {/* Main */}
      <div className="flex min-w-0 flex-col">
        <header className="sticky top-0 z-20 border-b border-border bg-background/80 backdrop-blur">
          <div className="flex items-center gap-4 px-5 py-4 sm:px-8">
            <button
              onClick={() => setOpen(true)}
              className="grid size-9 place-items-center rounded-lg border border-border lg:hidden"
              aria-label="Open menu"
            >
              <Menu className="size-5" />
            </button>
            <div className="min-w-0">
              <h1 className="truncate text-xl font-semibold tracking-tight">{title}</h1>
              {subtitle ? <p className="truncate text-sm text-muted-foreground">{subtitle}</p> : null}
            </div>
            <div className="ml-auto flex items-center gap-2">
              {actions}
              <button
                onClick={toggle}
                aria-label="Toggle theme"
                className="grid size-9 place-items-center rounded-lg border border-border hover:bg-muted"
              >
                {theme === "dark" ? <Sun className="size-4" /> : <Moon className="size-4" />}
              </button>
            </div>
          </div>
        </header>

        <main className="mx-auto w-full max-w-[1200px] flex-1 px-5 py-6 sm:px-8">{children}</main>
      </div>
    </div>
  );
}
