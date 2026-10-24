import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, x-admin-secret, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PATCH, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  const expectedSecret = Deno.env.get("ADMIN_PANEL_SECRET")?.trim();
  const providedSecret = req.headers.get("x-admin-secret")?.trim();
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  try {
    // Le secret historique reste réservé au panneau web. L'application
    // utilise sa session ; aucun secret administrateur n'est embarqué.
    let actorId: string | null = null;
    if (!expectedSecret || providedSecret !== expectedSecret) {
      const token = req.headers.get("authorization")?.match(/^Bearer\s+(.+)$/i)?.[1];
      if (!token) return jsonResponse({ error: "UNAUTHORIZED" }, 401);
      const { data, error } = await admin.auth.getUser(token);
      if (error || !data.user) return jsonResponse({ error: "UNAUTHORIZED" }, 401);
      if (data.user.app_metadata?.role !== "admin") return jsonResponse({ error: "FORBIDDEN" }, 403);
      const profile = await admin.from("profiles").select("is_active, valid_until").eq("id", data.user.id).single();
      if (profile.error || !profile.data?.is_active ||
          (profile.data.valid_until && new Date(profile.data.valid_until).getTime() <= Date.now())) {
        return jsonResponse({ error: "FORBIDDEN" }, 403);
      }
      actorId = data.user.id;
    }
    if (req.method === "GET") return await listUsers(admin);
    if (req.method === "POST") return await createUser(req, admin);
    if (req.method === "PATCH") return await updateUser(req, admin, actorId);
    return jsonResponse({ error: "METHOD_NOT_ALLOWED" }, 405);
  } catch (error) {
    return jsonResponse({ error: error instanceof Error ? error.message : "INTERNAL_ERROR" }, 500);
  }
});

type AdminClient = ReturnType<typeof createClient>;

async function listUsers(admin: AdminClient) {
  const [profilesResult, walletsResult, devicesResult, authResult] = await Promise.all([
    admin.from("profiles").select("id, username, max_devices, valid_until, is_active, created_at").order("created_at", { ascending: false }),
    admin.from("wallets").select("user_id, balance"),
    admin.from("user_devices").select("user_id"),
    admin.auth.admin.listUsers({ page: 1, perPage: 1000 }),
  ]);

  const error = profilesResult.error || walletsResult.error || devicesResult.error || authResult.error;
  if (error) return jsonResponse({ error: error.message }, 400);

  const balances = new Map((walletsResult.data ?? []).map((row) => [row.user_id, row.balance]));
  const deviceCounts = new Map<string, number>();
  for (const row of devicesResult.data ?? []) {
    deviceCounts.set(row.user_id, (deviceCounts.get(row.user_id) ?? 0) + 1);
  }
  const authUsers = new Map((authResult.data.users ?? []).map((user) => [user.id, user]));

  const users = (profilesResult.data ?? []).map((profile) => {
    const authUser = authUsers.get(profile.id);
    return {
      ...profile,
      email: authUser?.email ?? null,
      last_sign_in_at: authUser?.last_sign_in_at ?? null,
      balance: balances.get(profile.id) ?? 0,
      device_count: deviceCounts.get(profile.id) ?? 0,
    };
  });
  return jsonResponse({ users }, 200);
}

async function createUser(req: Request, admin: AdminClient) {
  const body = await readJson(req);
  const username = normalizeUsername(body.username);
  const password = typeof body.password === "string" ? body.password : "";
  const maxDevices = positiveInteger(body.maxDevices, 1);
  const validityDays = positiveInteger(body.validityDays, 30);

  if (!validUsername(username)) return jsonResponse({ error: "INVALID_USERNAME" }, 400);
  if (password.length < 6) return jsonResponse({ error: "INVALID_PASSWORD" }, 400);
  if (!validLimits(body)) return jsonResponse({ error: "INVALID_LIMITS" }, 400);

  const { data, error } = await admin.auth.admin.createUser({
    email: emailFor(username),
    password,
    email_confirm: true,
    ...(body.isActive === false ? { ban_duration: BAN_FOREVER } : {}),
    user_metadata: { username, max_devices: maxDevices, validity_days: validityDays },
  });
  if (error) return jsonResponse({ error: error.message }, 400);
  if (body.isActive === false && data.user) {
    const profile = await admin.from("profiles").update({ is_active: false }).eq("id", data.user.id);
    if (profile.error) return jsonResponse({ error: profile.error.message }, 400);
  }

  return jsonResponse({ success: true, userId: data.user?.id, username, password, maxDevices, validityDays }, 200);
}

// Durée de blocage Auth équivalente à "pour toujours" (~100 ans).
const BAN_FOREVER = "876000h";

// Bloque ou débloque un compte sans toucher au reste (validité, mot de passe,
// appareils). is_active est vérifié par les triggers SQL (0006) et register_device ;
// le ban Auth empêche en plus toute nouvelle connexion et tout renouvellement
// de session.
async function setActive(body: Record<string, unknown>, admin: AdminClient) {
  const userId = typeof body.userId === "string" ? body.userId : "";
  if (!userId) return jsonResponse({ error: "INVALID_USER_ID" }, 400);
  if (typeof body.isActive !== "boolean") return jsonResponse({ error: "INVALID_IS_ACTIVE" }, 400);
  const isActive = body.isActive;

  const profileResult = await admin.from("profiles").update({
    is_active: isActive,
    updated_at: new Date().toISOString(),
  }).eq("id", userId).select("id");
  if (profileResult.error) return jsonResponse({ error: profileResult.error.message }, 400);
  if (!profileResult.data?.length) return jsonResponse({ error: "USER_NOT_FOUND" }, 404);

  const authResult = await admin.auth.admin.updateUserById(userId, {
    ban_duration: isActive ? "none" : BAN_FOREVER,
  });
  if (authResult.error) return jsonResponse({ error: authResult.error.message }, 400);

  return jsonResponse({ success: true, userId, isActive }, 200);
}

async function updateUser(req: Request, admin: AdminClient, actorId: string | null) {
  const body = await readJson(req);
  if (actorId && body.userId === actorId && body.isActive !== true) {
    return jsonResponse({ error: "SELF_DISABLE_FORBIDDEN" }, 400);
  }
  if (body.action === "setActive") return await setActive(body, admin);
  const userId = typeof body.userId === "string" ? body.userId : "";
  const username = normalizeUsername(body.username);
  const maxDevices = positiveInteger(body.maxDevices, 1);
  const validityDays = positiveInteger(body.validityDays, 30);
  const isActive = body.isActive === true;
  const password = typeof body.password === "string" ? body.password : "";

  if (!userId) return jsonResponse({ error: "INVALID_USER_ID" }, 400);
  if (!validUsername(username)) return jsonResponse({ error: "INVALID_USERNAME" }, 400);
  if (password && password.length < 6) return jsonResponse({ error: "INVALID_PASSWORD" }, 400);
  if (!validLimits(body)) return jsonResponse({ error: "INVALID_LIMITS" }, 400);

  const current = await admin.auth.admin.getUserById(userId);
  if (current.error) return jsonResponse({ error: current.error.message }, 404);

  const authUpdate = {
    email: emailFor(username),
    email_confirm: true,
    ban_duration: isActive ? "none" : BAN_FOREVER,
    ...(password ? { password } : {}),
    user_metadata: {
      ...(current.data.user.user_metadata ?? {}),
      username,
      max_devices: maxDevices,
      validity_days: validityDays,
    },
  };

  const authResult = await admin.auth.admin.updateUserById(userId, authUpdate);
  if (authResult.error) return jsonResponse({ error: authResult.error.message }, 400);

  const validUntil = new Date(Date.now() + validityDays * 86400000).toISOString();
  const profileResult = await admin.from("profiles").update({
    username,
    max_devices: maxDevices,
    valid_until: validUntil,
    is_active: isActive,
    updated_at: new Date().toISOString(),
  }).eq("id", userId);
  if (profileResult.error) return jsonResponse({ error: profileResult.error.message }, 400);

  if (body.clearDevices === true) {
    const clearResult = await admin.from("user_devices").delete().eq("user_id", userId);
    if (clearResult.error) return jsonResponse({ error: clearResult.error.message }, 400);
  }

  return jsonResponse({ success: true, userId }, 200);
}

async function readJson(req: Request): Promise<Record<string, unknown>> {
  try {
    return await req.json();
  } catch {
    throw new Error("INVALID_BODY");
  }
}

function normalizeUsername(value: unknown) {
  return typeof value === "string" ? value.trim().toLowerCase() : "";
}

function validUsername(value: string) {
  return /^[a-z0-9._-]{3,40}$/.test(value);
}

function emailFor(username: string) {
  return `${username}@underover7.local`;
}

function positiveInteger(value: unknown, fallback: number) {
  return Number.isInteger(value) && (value as number) > 0 ? value as number : fallback;
}

function validLimits(body: Record<string, unknown>) {
  return (body.maxDevices === undefined || (Number.isInteger(body.maxDevices) && Number(body.maxDevices) >= 1 && Number(body.maxDevices) <= 100)) &&
    (body.validityDays === undefined || (Number.isInteger(body.validityDays) && Number(body.validityDays) >= 1 && Number(body.validityDays) <= 3650));
}

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
