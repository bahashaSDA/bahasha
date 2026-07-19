"use client";

import { useEffect, useState } from "react";
import { getSupabase, isSupabaseConfigured } from "./supabase";

export interface ChurchSummary {
  church_id: string;
  church_name: string;
  city: string | null;
  is_active: boolean;
  total_given: number;
  contribution_count: number;
  completed_count: number;
  giver_count: number;
  anonymous_giver_count: number;
  hub_status: string | null;
}

export interface AdminGiver {
  user_id: string;
  church_id: string;
  church_name: string;
  membership_status: string | null;
  visibility: "open" | "secret";
  registered_at: string;
  display_name: string;
  pseudonym: string | null;
  total_given: number;
  contribution_count: number;
}

export interface AdminHub {
  hub_id: string;
  church_name: string;
  name: string;
  status: string;
  last_upload_at: string | null;
  last_heartbeat_at: string | null;
  is_active: boolean;
}

export interface RevealLog {
  revealed_at: string;
  admin_name: string;
  admin_email: string;
  giver_church: string;
  reason: string;
}

/** Detects whether the signed-in user is a super admin (reads their admin row). */
export function useIsSuperAdmin(): { isSuperAdmin: boolean; loading: boolean; signedIn: boolean } {
  const [state, setState] = useState({ isSuperAdmin: false, loading: true, signedIn: false });

  useEffect(() => {
    if (!isSupabaseConfigured()) {
      setState({ isSuperAdmin: false, loading: false, signedIn: false });
      return;
    }
    let active = true;
    (async () => {
      const supabase = getSupabase();
      const { data: session } = await supabase.auth.getSession();
      if (!session.session) {
        if (active) setState({ isSuperAdmin: false, loading: false, signedIn: false });
        return;
      }
      const { data } = await supabase
        .from("admins")
        .select("role")
        .eq("id", session.session.user.id)
        .maybeSingle();
      if (active)
        setState({
          isSuperAdmin: data?.role === "super_admin",
          loading: false,
          signedIn: true,
        });
    })();
    return () => {
      active = false;
    };
  }, []);

  return state;
}

// --- Data accessors (each backed by a SECURITY DEFINER RPC) ------------------

export async function fetchChurchSummary(): Promise<ChurchSummary[]> {
  const { data, error } = await getSupabase().rpc("get_admin_church_summary");
  if (error) throw error;
  return (data ?? []) as ChurchSummary[];
}

export async function fetchGivers(): Promise<AdminGiver[]> {
  const { data, error } = await getSupabase().rpc("get_admin_givers");
  if (error) throw error;
  return (data ?? []) as AdminGiver[];
}

export async function fetchHubs(): Promise<AdminHub[]> {
  const { data, error } = await getSupabase().rpc("get_admin_hubs");
  if (error) throw error;
  return (data ?? []) as AdminHub[];
}

export async function fetchReveals(): Promise<RevealLog[]> {
  const { data, error } = await getSupabase().rpc("get_admin_reveals");
  if (error) throw error;
  return (data ?? []) as RevealLog[];
}

/** The audited unmask. Requires a reason (>= 10 chars). Logs, then returns the identity. */
export async function revealIdentity(
  userId: string,
  reason: string,
): Promise<{ full_name: string; phone: string; church_name: string }> {
  const { data, error } = await getSupabase().rpc("reveal_giver_identity", {
    p_user_id: userId,
    p_reason: reason,
  });
  if (error) throw error;
  const row = Array.isArray(data) ? data[0] : data;
  return row as { full_name: string; phone: string; church_name: string };
}
