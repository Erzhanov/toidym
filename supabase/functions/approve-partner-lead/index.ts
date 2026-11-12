// ============================================================================
// toıdym Edge Function: approve-partner-lead
// Admin approves or rejects a PENDING venue lead; on approval, provisions
// a PARTNER account with a temporary password (is_first_login = true).
// ============================================================================

import { resolveCallerAccess, syncStaffProfile } from '../_shared/auth.ts';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';

function generateTempPassword(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(6));
  const suffix = Array.from(bytes, (b) => b.toString(36).slice(-1)).join('').toUpperCase();
  return `Toidym#${suffix}9`;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const authResult = await resolveCallerAccess(req);
  if (!authResult.ok) {
    return jsonResponse({ error: authResult.error }, authResult.status);
  }
  const { supabaseAdmin, user: callerUser, role: callerRole } = authResult.access;
  if (callerRole !== 'ADMIN') {
    return jsonResponse({ error: 'Forbidden: ADMIN role required' }, 403);
  }

  const payload = await req.json();
  const venueId = String(payload.venue_id ?? '');
  const approved = Boolean(payload.approved ?? true);
  const rejectionFields = Array.isArray(payload.rejection_fields)
    ? payload.rejection_fields.map(String)
    : [];
  const rejectionComment = payload.rejection_comment
    ? String(payload.rejection_comment)
    : null;

  if (!venueId) {
    return jsonResponse({ error: 'venue_id is required' }, 400);
  }

  const { data: venue, error: venueErr } = await supabaseAdmin
    .from('venues')
    .select('*')
    .eq('id', venueId)
    .single();

  if (venueErr || !venue) {
    return jsonResponse({ error: 'Venue not found' }, 404);
  }

  if (!approved) {
    const { data: rejected, error: rejErr } = await supabaseAdmin
      .from('venues')
      .update({
        status: 'REJECTED',
        rejection_fields: rejectionFields,
        rejection_comment: rejectionComment ?? 'Проверьте корректность заявки',
      })
      .eq('id', venueId)
      .select()
      .single();

    if (rejErr) {
      return jsonResponse({ error: rejErr.message }, 500);
    }

    await supabaseAdmin.from('audit_logs').insert({
      actor_id: callerUser.id,
      actor_email: callerUser.email ?? 'admin@toidym.kz',
      action: 'REJECT_VENUE',
      target_type: 'venue',
      target_id: venueId,
      details: `Отклонена заявка «${venue.name}»: ${rejectionComment ?? '-'}`,
    });

    return jsonResponse({ ok: true, venue: rejected });
  }

  // Approve venue & provision PARTNER account
  const partnerEmail = String(
    payload.partner_email ||
      venue.applicant_email ||
      `partner.${venueId.slice(0, 8)}@toidym.kz`,
  ).toLowerCase();
  const tempPassword = generateTempPassword();

  let ownerId = venue.owner_id as string | null;
  if (!ownerId) {
    const { data: existingProfile } = await supabaseAdmin
      .from('profiles')
      .select('id')
      .eq('email', partnerEmail)
      .maybeSingle();

    if (existingProfile?.id) {
      ownerId = existingProfile.id as string;
      await supabaseAdmin.auth.admin.updateUserById(ownerId, {
        password: tempPassword,
        app_metadata: {
          role: 'PARTNER',
          managed_venue_id: venueId,
          is_first_login: true,
        },
      });
      await supabaseAdmin
        .from('profiles')
        .update({
          role: 'PARTNER',
          managed_venue_id: venueId,
          is_first_login: true,
          is_verified: true,
        })
        .eq('id', ownerId);
    } else {
      const { data: createdAuth, error: createErr } =
        await supabaseAdmin.auth.admin.createUser({
          email: partnerEmail,
          password: tempPassword,
          email_confirm: true,
          app_metadata: {
            role: 'PARTNER',
            managed_venue_id: venueId,
            is_first_login: true,
          },
          user_metadata: {
            name: `Партнёр ${venue.name}`,
            phone: venue.phone,
          },
        });

      if (createErr || !createdAuth.user) {
        return jsonResponse(
          { error: createErr?.message ?? 'Failed to provision partner user' },
          500,
        );
      }
      ownerId = createdAuth.user.id;
    }
  }

  await syncStaffProfile(supabaseAdmin, {
    userId: ownerId,
    email: partnerEmail,
    name: `Партнёр ${venue.name}`,
    phone: String(venue.phone ?? ''),
    role: 'PARTNER',
    venueId,
  });

  const { data: updatedVenue, error: updErr } = await supabaseAdmin
    .from('venues')
    .update({
      status: 'APPROVED',
      owner_id: ownerId,
      rejection_fields: [],
      rejection_comment: null,
    })
    .eq('id', venueId)
    .select()
    .single();

  if (updErr) {
    return jsonResponse({ error: updErr.message }, 500);
  }

  await supabaseAdmin.from('audit_logs').insert({
    actor_id: callerUser.id,
    actor_email: callerUser.email ?? 'admin@toidym.kz',
    action: 'APPROVE_VENUE',
    target_type: 'venue',
    target_id: venueId,
    details: `Одобрена заявка «${venue.name}», партнёр ${partnerEmail}`,
  });

  return jsonResponse({
    ok: true,
    venue: updatedVenue,
    partner_email: partnerEmail,
    temp_password: tempPassword,
  });
});
