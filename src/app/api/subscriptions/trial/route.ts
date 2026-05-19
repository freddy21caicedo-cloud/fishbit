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

  // Get current user
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) {
    return NextResponse.json({ error: 'No autorizado' }, { status: 401 })
  }

  // Get active unit ID from body
  let body
  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: 'Body JSON inválido' }, { status: 400 })
  }

  const { unitId } = body
  if (!unitId) {
    return NextResponse.json({ error: 'Falta unitId' }, { status: 400 })
  }

  // Check if user is admin or propietario of the unit in user_units
  const { data: userUnit, error: roleError } = await supabase
    .from('user_units')
    .select('role')
    .eq('user_id', user.id)
    .eq('unit_id', unitId)
    .maybeSingle()

  if (roleError || !userUnit || (userUnit.role !== 'admin' && userUnit.role !== 'propietario')) {
    return NextResponse.json({ error: 'No tienes permisos para modificar la suscripción de esta unidad' }, { status: 403 })
  }

  // Check if a trial was already activated (trial_activated_at IS NOT NULL)
  const { data: sub, error: subError } = await supabase
    .from('subscriptions')
    .select('trial_activated_at')
    .eq('unit_id', unitId)
    .maybeSingle()

  if (sub?.trial_activated_at) {
    return NextResponse.json({ error: 'El mes de prueba gratuito ya ha sido activado previamente en esta unidad' }, { status: 400 })
  }

  // Calculate next billing date: 30 days from now
  const nextBillingDate = new Date()
  nextBillingDate.setDate(nextBillingDate.getDate() + 30)

  // Upsert subscription
  const subscriptionData = {
    unit_id: unitId,
    plan_type: 'basic',
    status: 'active',
    price: 0,
    next_billing_date: nextBillingDate.toISOString().split('T')[0],
    trial_activated_at: new Date().toISOString()
  }

  let upsertError
  if (sub) {
    // Update existing subscription
    const { error } = await supabase
      .from('subscriptions')
      .update(subscriptionData)
      .eq('unit_id', unitId)
    upsertError = error
  } else {
    // Insert new subscription
    const { error } = await supabase
      .from('subscriptions')
      .insert([subscriptionData])
    upsertError = error
  }

  if (upsertError) {
    return NextResponse.json({ error: 'Error al activar la suscripción de prueba: ' + upsertError.message }, { status: 500 })
  }

  return NextResponse.json({ success: true, message: 'Mes de prueba gratis activado con éxito' })
}
