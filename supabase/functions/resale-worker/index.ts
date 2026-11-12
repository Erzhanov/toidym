// ============================================================================
// toıdym Edge Function: resale-worker
// Runs the 1-minute Auto-Resale DB transaction & dispatches FCM Strike pushes.
// Required Secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, CRON_SECRET
// Optional Secret: FCM_LEGACY_SERVER_KEY
// ============================================================================

import { createClient } from 'npm:@supabase/supabase-js@2';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  const cronSecret = Deno.env.get('CRON_SECRET') ?? '';
  const fcmKey = Deno.env.get('FCM_LEGACY_SERVER_KEY') ?? '';

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: 'Missing Supabase server credentials' }, 500);
  }

  // Authorize via CRON_SECRET header OR Bearer service_role key
  const reqSecret = req.headers.get('x-cron-secret') ?? '';
  const authHeader = req.headers.get('authorization') ?? '';
  const bearerToken = authHeader.replace(/^Bearer\s+/i, '');

  const isAuthorized =
    (cronSecret.length > 0 && reqSecret === cronSecret) ||
    bearerToken === serviceRoleKey;

  if (!isAuthorized) {
    return jsonResponse({ error: 'Unauthorized CRON trigger' }, 401);
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // 1. Execute atomic DB Resale Worker + Archiver
  const { data: rpcResult, error: rpcError } = await supabaseAdmin.rpc(
    'api_run_resale_cron_worker',
  );

  if (rpcError) {
    return jsonResponse({ error: rpcError.message }, 500);
  }

  // 2. Dispatch pending FCM push notifications created by Resale Worker
  let pushesSent = 0;
  if (fcmKey.length > 0) {
    const { data: pending } = await supabaseAdmin
      .from('notifications')
      .select('id, title_ru, title_kk, body_ru, body_kk, profiles(fcm_token, language)')
      .is('push_sent_at', null)
      .limit(50);

    if (pending && pending.length > 0) {
      const sentIds: string[] = [];
      for (const row of pending) {
        const profile = Array.isArray(row.profiles)
          ? row.profiles[0]
          : row.profiles;
        const token = profile?.fcm_token as string | undefined;
        const lang = profile?.language === 'kk' ? 'kk' : 'ru';
        if (!token) continue;

        const res = await fetch('https://fcm.googleapis.com/fcm/send', {
          method: 'POST',
          headers: {
            Authorization: `key=${fcmKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            to: token,
            notification: {
              title: lang === 'kk' ? row.title_kk : row.title_ru,
              body: lang === 'kk' ? row.body_kk : row.body_ru,
            },
            data: { type: 'NO_SHOW_STRIKE', notification_id: row.id },
          }),
        });

        if (res.ok) {
          pushesSent += 1;
          sentIds.push(row.id as string);
        }
      }

      if (sentIds.length > 0) {
        await supabaseAdmin
          .from('notifications')
          .update({ push_sent_at: new Date().toISOString() })
          .in('id', sentIds);
      }
    }
  }

  return jsonResponse({
    ok: true,
    worker: rpcResult,
    pushes_sent: pushesSent,
  });
});
