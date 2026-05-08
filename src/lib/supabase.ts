import { createBrowserClient } from '@supabase/ssr';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

// createBrowserClient defaults to using localStorage for persistence
// and is designed to work with Next.js SSR and the middleware.
export const supabase = createBrowserClient(supabaseUrl, supabaseAnonKey);
