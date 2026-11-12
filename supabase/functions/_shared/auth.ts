import { createClient, type SupabaseClient, type User } from 'npm:@supabase/supabase-js@2';

export interface CallerAccess {
  supabaseAdmin: SupabaseClient;
  user: User;
  role: string;
  managedVenueId?: string;
}

/**
 * Verifies the incoming Bearer JWT and resolves the caller's role and managed
 * venue from auth app_metadata, falling back to profiles / user_roles tables.
 */
export async function resolveCallerAccess(req: Request): Promise<
  | { ok: true; access: CallerAccess }
  | { ok: false; status: number; error: string }
> {
  const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
  const anonKey =
    Deno.env.get('SUPABASE_ANON_KEY') ??
    Deno.env.get('SUPABASE_PUBLISHABLE_KEY') ??
    '';
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return { ok: false, status: 500, error: 'Missing server configuration' };
  }

  const authHeader = req.headers.get('authorization');
  if (!authHeader) {
    return { ok: false, status: 401, error: 'Missing Authorization header' };
  }

  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: callerData, error: callerErr } = await callerClient.auth.getUser();
  if (callerErr || !callerData.user) {
    return { ok: false, status: 401, error: 'Invalid session' };
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const user = callerData.user;
  let role = String(user.app_metadata?.role ?? '').toUpperCase();
  let managedVenueId = user.app_metadata?.managed_venue_id as string | undefined;

  if (!role || !managedVenueId) {
    const { data: profile } = await supabaseAdmin
      .from('profiles')
      .select('role, managed_venue_id')
      .eq('id', user.id)
      .maybeSingle();

    if (profile) {
      if (!role && profile.role) {
        role = String(profile.role).toUpperCase();
      }
      if (!managedVenueId && profile.managed_venue_id) {
        managedVenueId = String(profile.managed_venue_id);
      }
    }
  }

  if (!role || role === 'USER') {
    const { data: roleRows } = await supabaseAdmin
      .from('user_roles')
      .select('role')
      .eq('user_id', user.id);

    const mapped = (roleRows ?? [])
      .map((r) => String(r.role ?? '').toUpperCase())
      .filter((r) => ['ADMIN', 'PARTNER', 'CASHIER'].includes(r));

    if (mapped.includes('ADMIN')) {
      role = 'ADMIN';
    } else if (mapped.includes('PARTNER')) {
      role = 'PARTNER';
    } else if (mapped.includes('CASHIER')) {
      role = 'CASHIER';
    }
  }

  return {
    ok: true,
    access: {
      supabaseAdmin,
      user,
      role: role || 'USER',
      managedVenueId,
    },
  };
}

/**
 * Ensures profiles and venue_staff reflect the assigned PARTNER/CASHIER role
 * even if the database's auth trigger does not copy custom metadata fields.
 */
export async function syncStaffProfile(
  supabaseAdmin: SupabaseClient,
  params: {
    userId: string;
    email: string;
    name: string;
    phone: string;
    role: 'PARTNER' | 'CASHIER';
    venueId: string;
  },
): Promise<void> {
  await supabaseAdmin.from('profiles').upsert({
    id: params.userId,
    email: params.email,
    name: params.name,
    phone: params.phone,
    role: params.role,
    managed_venue_id: params.venueId,
    is_first_login: true,
    is_verified: true,
  });

  await supabaseAdmin.from('venue_staff').upsert({
    venue_id: params.venueId,
    user_id: params.userId,
    staff_role: params.role,
  });
}
