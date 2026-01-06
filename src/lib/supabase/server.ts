import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error("Supabase サーバーキーまたはURLが設定されていません。");
}

let serverClient: SupabaseClient | null = null;

export function getServerSupabaseClient(): SupabaseClient {
  if (serverClient) return serverClient;

  serverClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      headers: { "X-Client-Info": "free-school-dashboard/server" },
    },
  });

  return serverClient;
}
