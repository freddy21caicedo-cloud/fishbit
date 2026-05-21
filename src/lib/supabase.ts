import { createBrowserClient } from '@supabase/ssr';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

// Singleton pattern: reuse the same client instance across the entire app
// to prevent multiple instances fighting over the localStorage auth lock.
let _supabase: ReturnType<typeof createBrowserClient> | null = null;

export function getSupabase() {
  if (_supabase) return _supabase;
  _supabase = createBrowserClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      // Reduce lock timeout — 5000ms (default) causes UI hangs in dev/Strict Mode.
      // 2000ms is enough time to read/write the token from localStorage.
      lockAcquireTimeout: 2000,
      // Keep storage as localStorage (default) — just with a faster lock timeout.
      storage: typeof window !== 'undefined' ? window.localStorage : undefined,
      // Don't auto-refresh on every tab focus — reduces redundant lock acquisitions.
      detectSessionInUrl: true,
      persistSession: true,
    },
  } as any);
  return _supabase;
}

// Named export for backward compatibility with all existing imports
export const supabase = getSupabase();
