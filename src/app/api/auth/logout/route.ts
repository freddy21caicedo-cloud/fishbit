import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function POST(request: Request) {
  const cookieStore = await cookies()
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value
        },
        set(name: string, value: string, options: any) {
          try {
            cookieStore.set({ name, value, ...options })
          } catch (error) {
            // Can be ignored
          }
        },
        remove(name: string, options: any) {
          try {
            cookieStore.delete({ name, ...options })
          } catch (error) {
            // Can be ignored
          }
        },
      },
    }
  )

  // 1. Sign out on the server side and AWAIT the promise so that cookie removals are set in the response headers.
  // We use Promise.race to guarantee that network or Supabase database hangs won't block the response.
  try {
    await Promise.race([
      supabase.auth.signOut(),
      new Promise((resolve) => setTimeout(resolve, 800))
    ]);
  } catch (err) {
    console.error('Server-side signOut timed out or failed:', err);
  }

  // 2. Extract hostname to clear cookies on all matching domain levels (exact, wildcard subdomains, and parent domains)
  const host = request.headers.get('host') || '';
  const hostname = host.split(':')[0]; // Remove port if present

  // 3. Aggressively delete all Supabase cookies from the cookie store using matching domain parameters
  try {
    const allCookies = cookieStore.getAll()
    for (const cookie of allCookies) {
      if (cookie.name.startsWith('sb-') || cookie.name.includes('auth-token')) {
        // Clear with no domain parameter (defaults to exact path)
        try {
          cookieStore.delete({ name: cookie.name, path: '/' });
        } catch (e) {}

        if (hostname) {
          // Clear with exact hostname
          try {
            cookieStore.set({
              name: cookie.name,
              value: '',
              path: '/',
              maxAge: -1,
              expires: new Date(0),
              domain: hostname
            });
          } catch (e) {}

          // Clear with wildcard subdomain (.hostname)
          try {
            cookieStore.set({
              name: cookie.name,
              value: '',
              path: '/',
              maxAge: -1,
              expires: new Date(0),
              domain: `.${hostname}`
            });
          } catch (e) {}

          // If the hostname is a subdomain (e.g. app.fishbit.co), clear parent domain (fishbit.co)
          const parts = hostname.split('.');
          if (parts.length > 2) {
            const parentDomain = parts.slice(-2).join('.');
            try {
              cookieStore.set({
                name: cookie.name,
                value: '',
                path: '/',
                maxAge: -1,
                expires: new Date(0),
                domain: parentDomain
              });
            } catch (e) {}

            try {
              cookieStore.set({
                name: cookie.name,
                value: '',
                path: '/',
                maxAge: -1,
                expires: new Date(0),
                domain: `.${parentDomain}`
              });
            } catch (e) {}
          }
        }
      }
    }
  } catch (err) {
    console.error('Error aggressively clearing cookies on server:', err);
  }

  return NextResponse.json({ success: true })
}
