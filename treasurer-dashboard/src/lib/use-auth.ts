"use client";

import { useEffect, useState } from "react";
import type { Session } from "@supabase/supabase-js";
import { getSupabase, isSupabaseConfigured } from "./supabase";

interface AuthState {
  session: Session | null;
  email: string | null;
  loading: boolean;
  configured: boolean;
}

/**
 * Tracks the treasurer's Supabase Auth session. When signed in, the dashboard's
 * data layer switches from demo to the live RLS-scoped masking views; the
 * session is what scopes a treasurer to their own church.
 */
export function useAuth(): AuthState {
  const [state, setState] = useState<AuthState>({
    session: null,
    email: null,
    loading: true,
    configured: isSupabaseConfigured(),
  });

  useEffect(() => {
    if (!isSupabaseConfigured()) {
      setState((s) => ({ ...s, loading: false }));
      return;
    }
    const supabase = getSupabase();
    let active = true;

    supabase.auth.getSession().then(({ data }) => {
      if (!active) return;
      setState({
        session: data.session,
        email: data.session?.user.email ?? null,
        loading: false,
        configured: true,
      });
    });

    const { data: sub } = supabase.auth.onAuthStateChange((_event, session) => {
      setState({
        session,
        email: session?.user.email ?? null,
        loading: false,
        configured: true,
      });
    });

    return () => {
      active = false;
      sub.subscription.unsubscribe();
    };
  }, []);

  return state;
}

export async function signIn(email: string, password: string): Promise<void> {
  const supabase = getSupabase();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
}

export async function signOut(): Promise<void> {
  if (!isSupabaseConfigured()) return;
  await getSupabase().auth.signOut();
}
