import { createClient, type SupabaseClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !anonKey) {
  throw new Error("Supabase anonキーまたはURLが設定されていません。");
}

let browserClient: SupabaseClient | null = null;

export function getBrowserSupabaseClient(): SupabaseClient {
  if (browserClient) return browserClient;

  browserClient = createClient(supabaseUrl, anonKey, {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: true,
    },
    global: {
      headers: { "X-Client-Info": "free-school-dashboard/browser" },
    },
  });

  return browserClient;
}
