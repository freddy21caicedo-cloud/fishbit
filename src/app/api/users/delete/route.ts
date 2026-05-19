import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

export async function POST(request: Request) {
  const cookieStore = await cookies()
  const supabaseUserClient = createServerClient(
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
          } catch (error) {}
        },
        remove(name: string, options: any) {
          try {
            cookieStore.delete({ name, ...options })
          } catch (error) {}
        },
      },
    }
  )

  // 1. Get current logged-in user
  const { data: { user: currentUser } } = await supabaseUserClient.auth.getUser()
  if (!currentUser) {
    return NextResponse.json({ error: 'No autorizado' }, { status: 401 })
  }

  // 2. Read request body
  let body
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Body JSON inválido' }, { status: 400 })
  }

  const { userId } = body
  if (!userId) {
    return NextResponse.json({ error: 'Falta userId' }, { status: 400 })
  }

  // 3. Verify permissions (MUST be SuperAdmin)
  const { data: callerProfile } = await supabaseUserClient
    .from('profiles')
    .select('is_superadmin')
    .eq('id', currentUser.id)
    .maybeSingle()

  const isSuper = callerProfile?.is_superadmin || false
  if (!isSuper) {
    return NextResponse.json({ error: 'Prohibido: Solo los SuperAdministradores pueden eliminar usuarios definitivamente' }, { status: 403 })
  }

  // 4. Initialize Supabase Admin client with service_role key to delete the user
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  const supabaseAdmin = createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    serviceRoleKey,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  )

  // 5. Delete dependencies first
  const { error: uuError } = await supabaseAdmin
    .from('user_units')
    .delete()
    .eq('user_id', userId)

  if (uuError) {
    return NextResponse.json({ error: `Error al eliminar relaciones de unidad: ${uuError.message}` }, { status: 500 })
  }

  const { error: profileError } = await supabaseAdmin
    .from('profiles')
    .delete()
    .eq('id', userId)

  if (profileError) {
    return NextResponse.json({ error: `Error al eliminar perfil de la base de datos: ${profileError.message}` }, { status: 500 })
  }

  // 6. Delete from Supabase Auth
  const { error: authError } = await supabaseAdmin.auth.admin.deleteUser(userId)
  if (authError) {
    return NextResponse.json({ error: `Error al eliminar cuenta en Supabase Auth: ${authError.message}` }, { status: 500 })
  }

  return NextResponse.json({
    success: true,
    message: 'Usuario eliminado definitivamente del sistema'
  })
}
