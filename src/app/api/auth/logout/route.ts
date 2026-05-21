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

  try {
    // 1. Sign out on the server side (this invalidates the session in Supabase)
    await supabase.auth.signOut()
  } catch (err) {
    console.error('Error in server signOut:', err)
  }

  // 2. Aggressively delete all Supabase cookies from the cookie store
  try {
    const allCookies = cookieStore.getAll()
    for (const cookie of allCookies) {
      if (cookie.name.startsWith('sb-') || cookie.name.includes('auth-token')) {
        try {
          cookieStore.delete(cookie.name)
        } catch (e) {
          // Ignore
        }
      }
    }
  } catch (err) {
    console.error('Error clearing cookies on server:', err)
  }

  return NextResponse.json({ success: true })
}
