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

  // Protected routes logic
  const isProtectedRoute = 
    request.nextUrl.pathname.startsWith('/dashboard') || 
    request.nextUrl.pathname.startsWith('/superadmin') ||
    request.nextUrl.pathname.startsWith('/estanques') ||
    request.nextUrl.pathname.startsWith('/finanzas') ||
    request.nextUrl.pathname.startsWith('/siembra') ||
    request.nextUrl.pathname.startsWith('/registros') ||
    request.nextUrl.pathname.startsWith('/perfil') ||
    request.nextUrl.pathname.startsWith('/configuracion') ||
    request.nextUrl.pathname.startsWith('/aireacion') ||
    request.nextUrl.pathname.startsWith('/mantenimiento') ||
    request.nextUrl.pathname.startsWith('/tratamiento') ||
    request.nextUrl.pathname.startsWith('/almacen') ||
    request.nextUrl.pathname.startsWith('/ayuda')

  if (isProtectedRoute && !user) {
    return NextResponse.redirect(new URL('/', request.url))
  }

  // Redirect if already logged in and trying to access landing/login
  if (request.nextUrl.pathname === '/' && user) {
    // We might need to check profile for superadmin, but for now redirect to /dashboard
    return NextResponse.redirect(new URL('/dashboard', request.url))
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
     * Feel free to modify this pattern to include more paths.
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
