// Edge Function "play-game" (Phase 13).
//
// Rôle volontairement mince : valider la requête, transmettre le JWT de
// l'utilisateur, et déléguer tout le calcul atomique (tirage des dés,
// résultat, gain, mise à jour du solde) à la fonction PostgreSQL
// `play_round` (voir supabase/migrations/0002_play_round.sql).
// Le client Flutter ne reçoit jamais que le résultat déjà déterminé par
// le serveur — il ne peut ni choisir les dés ni modifier son solde.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const VALID_CHOICES = ["UNDER", "EQUAL", "OVER"];

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "AUTH_REQUIRED" }, 401);
  }

  let body: { choice?: unknown; stake?: unknown };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "INVALID_BODY" }, 400);
  }

  const { choice, stake } = body;
  if (typeof choice !== "string" || !VALID_CHOICES.includes(choice)) {
    return jsonResponse({ error: "INVALID_CHOICE" }, 400);
  }
  if (typeof stake !== "number" || !Number.isFinite(stake) || stake <= 0) {
    return jsonResponse({ error: "INVALID_STAKE" }, 400);
  }

  const supabaseClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data, error } = await supabaseClient.rpc("play_round", {
    p_choice: choice,
    p_stake: stake,
  });

  if (error) {
    return jsonResponse({ error: error.message }, 400);
  }

  return jsonResponse(data, 200);
});

function jsonResponse(body: unknown, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
