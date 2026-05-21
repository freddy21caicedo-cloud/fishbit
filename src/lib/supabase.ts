import { createBrowserClient } from '@supabase/ssr';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

// Singleton pattern: reuse the same client instance across the entire app
// to prevent multiple instances fighting over the localStorage auth lock.
let _supabase: ReturnType<typeof createBrowserClient> | null = null;

export function getSupabase() {
  if (_supabase) return _supabase;
  _supabase = createBrowserClient(supabaseUrl, supabaseAnonKey);
  return _supabase;
}

// Named export for backward compatibility with all existing imports
export const supabase = getSupabase();
