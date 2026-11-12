// ============================================================================
// toıdym Edge Function: create-partner
// Allows ADMIN to create a PARTNER + Venue, OR PARTNER to add a CASHIER
// for their own venue (generates one-time password with is_first_login=true).
// ============================================================================

import { resolveCallerAccess, syncStaffProfile } from '../_shared/auth.ts';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';

function generateTempPassword(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(6));
  const suffix = Array.from(bytes, (b) => b.toString(36).slice(-1)).join('').toUpperCase();
  return `Toidym#${suffix}7`;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const authResult = await resolveCallerAccess(req);
  if (!authResult.ok) {
    return jsonResponse({ error: authResult.error }, authResult.status);
  }
  const {
    supabaseAdmin,
    user: callerUser,
    role: callerRole,
    managedVenueId: callerVenueId,
  } = authResult.access;

  const body = await req.json();
  const targetRole = String(body.role ?? 'CASHIER').toUpperCase();
  const email = String(body.email ?? '').trim().toLowerCase();
  const name = String(body.name ?? '').trim() || 'Сотрудник';
  const phone = String(body.phone ?? '').trim();
  const venueId = String(body.venue_id ?? callerVenueId ?? '').trim();

  if (!email || !venueId) {
    return jsonResponse({ error: 'email and venue_id are required' }, 400);
  }

  if (targetRole !== 'PARTNER' && targetRole !== 'CASHIER') {
    return jsonResponse({ error: 'Invalid staff role' }, 400);
  }

  // Only ADMIN can create PARTNER; PARTNER can add CASHIER only to own venue
  if (targetRole === 'PARTNER' && callerRole !== 'ADMIN') {
    return jsonResponse({ error: 'Only ADMIN can assign PARTNER role' }, 403);
  }
  if (
    targetRole === 'CASHIER' &&
    callerRole !== 'ADMIN' &&
    !(callerRole === 'PARTNER' && callerVenueId === venueId)
  ) {
    return jsonResponse({ error: 'Forbidden for this venue' }, 403);
  }

  const tempPassword = generateTempPassword();
  const { data: created, error: createErr } =
    await supabaseAdmin.auth.admin.createUser({
      email,
      password: tempPassword,
      email_confirm: true,
      app_metadata: {
        role: targetRole,
        managed_venue_id: venueId,
        is_first_login: true,
      },
      user_metadata: { name, phone },
    });

  if (createErr || !created.user) {
    return jsonResponse(
      { error: createErr?.message ?? 'User creation failed' },
      400,
    );
  }

  await syncStaffProfile(supabaseAdmin, {
    userId: created.user.id,
    email,
    name,
    phone,
    role: targetRole as 'PARTNER' | 'CASHIER',
    venueId,
  });

  if (targetRole === 'PARTNER') {
    await supabaseAdmin
      .from('venues')
      .update({ owner_id: created.user.id })
      .eq('id', venueId);
  }

  await supabaseAdmin.from('audit_logs').insert({
    actor_id: callerUser.id,
    actor_email: callerUser.email ?? 'admin@toidym.kz',
    action: `CREATE_${targetRole}`,
    target_type: 'user',
    target_id: created.user.id,
    details: `Создан ${targetRole} (${email}) для заведения ${venueId}`,
  });

  return jsonResponse({
    ok: true,
    user_id: created.user.id,
    email,
    role: targetRole,
    venue_id: venueId,
    temp_password: tempPassword,
  });
});
