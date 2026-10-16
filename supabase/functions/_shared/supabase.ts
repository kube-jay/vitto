import {
  createClient,
  type SupabaseClient,
  type User,
} from "npm:@supabase/supabase-js@2";
import { AppError } from "./http.ts";

const url = () => Deno.env.get("SUPABASE_URL")!;

/** Service-role client. Server only; never returned to callers. */
export function adminClient(): SupabaseClient {
  return createClient(url(), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/**
 * Authenticates the caller from the bearer token and returns a client that
 * acts as that user, so RLS applies to every read.
 */
export async function userContext(
  req: Request,
): Promise<{ user: User; client: SupabaseClient }> {
  const auth = req.headers.get("authorization") ?? "";
  const token = auth.replace(/^Bearer\s+/i, "");
  if (!token) throw new AppError("unauthenticated", "Sign in required");

  const client = createClient(url(), Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await client.auth.getUser(token);
  if (error || !data.user) {
    console.warn("auth.getUser failed", error?.message);
    throw new AppError("unauthenticated", "Invalid session");
  }
  return { user: data.user, client };
}

/** Maps a Postgres RPC error raised as `raise exception '<code>'`. */
export function rpcError(
  error: { message?: string; details?: string } | null,
): never {
  const known = [
    "unauthenticated",
    "forbidden",
    "validation_error",
    "conflict",
    "listing_not_available",
    "invalid_state",
    "payment_pending",
    "rate_limited",
  ];
  const code = known.includes(error?.message ?? "")
    ? error!.message as AppError["code"]
    : "internal_error";
  if (code === "internal_error") console.error(error);
  throw new AppError(code, error?.details ?? code);
}
