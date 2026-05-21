import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  let response = NextResponse.next({
    request: {
      headers: request.headers,
    },
  })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return request.cookies.get(name)?.value
        },
        set(name: string, value: string, options: CookieOptions) {
          request.cookies.set({
            name,
            value,
            ...options,
          })
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value,
            ...options,
          })
        },
        remove(name: string, options: CookieOptions) {
          request.cookies.set({
            name,
            value: '',
            ...options,
          })
          response = NextResponse.next({
            request: {
              headers: request.headers,
            },
          })
          response.cookies.set({
            name,
            value: '',
            ...options,
          })
        },
      },
    }
  )

  const { data: { user } } = await supabase.auth.getUser()

  const pathname = request.nextUrl.pathname
  const isPublicRoute = pathname === '/' || pathname === '/signup'
  // Routes that are accessible while authenticated but should NOT redirect to dashboard
  const isSelectUnitRoute = pathname === '/select-unit' || pathname.startsWith('/select-unit/')

  // If user is not logged in and attempts to access any non-public page, redirect to login
  if (!user) {
    if (!isPublicRoute) {
      return NextResponse.redirect(new URL('/', request.url))
    }
    return response
  }

  // select-unit is accessible while logged in — don't redirect to dashboard
  if (isSelectUnitRoute) {
    return response
  }

  // Only query the DB for superadmin status when strictly needed:
  // accessing /superadmin, or on the login page redirect logic
  const needsSuperAdminCheck = pathname.startsWith('/superadmin') || isPublicRoute

  let isSuperAdmin = !!user.app_metadata?.is_superadmin
  if (!isSuperAdmin && needsSuperAdminCheck) {
    try {
      const { data: profile } = await supabase
        .from('profiles')
        .select('is_superadmin')
        .eq('id', user.id)
        .maybeSingle()
      isSuperAdmin = profile?.is_superadmin || false
    } catch (err) {
      console.error('Error fetching role in middleware:', err)
    }
  }

  // Protect /superadmin route
  if (pathname.startsWith('/superadmin')) {
    if (!isSuperAdmin) {
      return NextResponse.redirect(new URL('/dashboard', request.url))
    }
  }

  // Redirect if logged in and trying to access landing/login
  if (isPublicRoute) {
    if (isSuperAdmin) {
      return NextResponse.redirect(new URL('/superadmin', request.url))
    } else {
      return NextResponse.redirect(new URL('/dashboard', request.url))
    }
  }

  return response
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - api/ routes (handled server-side, no auth redirect needed)
     * - manifest.json, service workers, static assets
     */
    '/((?!_next/static|_next/image|favicon.ico|api/|manifest\\.json|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico)$).*)',
  ],
}
