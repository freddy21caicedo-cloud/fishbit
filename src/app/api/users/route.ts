import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'
import { createClient } from '@supabase/supabase-js'

// Simple password generator
function generateRandomPassword() {
  const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  const lower = 'abcdefghijklmnopqrstuvwxyz'
  const digits = '0123456789'
  const special = '!@#$%^&*'
  const all = upper + lower + digits + special
  
  let password = ''
  password += upper[Math.floor(Math.random() * upper.length)]
  password += lower[Math.floor(Math.random() * lower.length)]
  password += digits[Math.floor(Math.random() * digits.length)]
  password += special[Math.floor(Math.random() * special.length)]
  
  for (let i = 0; i < 10; i++) {
    password += all[Math.floor(Math.random() * all.length)]
  }
  
  return password.split('').sort(() => 0.5 - Math.random()).join('')
}

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

  const { email, fullName, role, password: customPassword, unitId } = body
  if (!email || !fullName || !role) {
    return NextResponse.json({ error: 'Faltan campos obligatorios: email, fullName, role' }, { status: 400 })
  }

  // 3. Verify permissions (Is SuperAdmin or Admin/Propietario of the target unit)
  const { data: callerProfile } = await supabaseUserClient
    .from('profiles')
    .select('is_superadmin, role')
    .eq('id', currentUser.id)
    .maybeSingle()

  const isSuper = callerProfile?.is_superadmin || false

  if (!isSuper) {
    // If not superadmin, must specify unitId and be admin/propietario of that unit
    if (!unitId) {
      return NextResponse.json({ error: 'Falta unitId para usuarios que no son SuperAdmin' }, { status: 400 })
    }

    const { data: userUnitRelation } = await supabaseUserClient
      .from('user_units')
      .select('role')
      .eq('user_id', currentUser.id)
      .eq('unit_id', unitId)
      .maybeSingle()

    const hasPermission = userUnitRelation?.role === 'admin' || userUnitRelation?.role === 'propietario'
    if (!hasPermission) {
      return NextResponse.json({ error: 'No tienes permisos para invitar miembros a esta unidad' }, { status: 403 })
    }
  }

  // 4. Initialize Supabase Admin client with service_role key to bypass signUp session swapping
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY! // fallback to anon if service role isn't defined, but service role is required for auth.admin
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

  const finalPassword = customPassword || generateRandomPassword()

  // 5. Create user in Supabase Auth
  const { data: newAuthUser, error: authError } = await supabaseAdmin.auth.admin.createUser({
    email,
    password: finalPassword,
    email_confirm: true,
    user_metadata: { full_name: fullName }
  })

  if (authError || !newAuthUser.user) {
    return NextResponse.json({ error: `Error creando usuario en Auth: ${authError?.message || 'Usuario no creado'}` }, { status: 500 })
  }

  const userId = newAuthUser.user.id

  // 6. Create Profile record (profiles table RLS allows writing or we can write via admin client)
  // Let's write via admin client to ensure RLS bypass works correctly for service role
  const { error: profileError } = await supabaseAdmin
    .from('profiles')
    .insert([{
      id: userId,
      full_name: fullName,
      email: email,
      role: role,
      is_superadmin: false
    }])

  if (profileError) {
    // Cleanup created auth user if profile insert fails
    await supabaseAdmin.auth.admin.deleteUser(userId)
    return NextResponse.json({ error: `Error creando perfil: ${profileError.message}` }, { status: 500 })
  }

  // 7. If unitId is provided, link user to unit
  if (unitId) {
    const { error: linkError } = await supabaseAdmin
      .from('user_units')
      .insert([{
        user_id: userId,
        unit_id: unitId,
        role: role
      }])

    if (linkError) {
      // Cleanup profile and auth user if link fails
      await supabaseAdmin.from('profiles').delete().eq('id', userId)
      await supabaseAdmin.auth.admin.deleteUser(userId)
      return NextResponse.json({ error: `Error vinculando usuario a unidad: ${linkError.message}` }, { status: 500 })
    }
  }

  return NextResponse.json({
    success: true,
    user: {
      id: userId,
      email,
      fullName,
      role
    },
    password: finalPassword // return password so admins can copy it!
  })
}
