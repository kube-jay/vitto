// Response envelope shared by every Edge Function (docs/contracts/functions.md).

export type ErrorCode =
  | "unauthenticated"
  | "forbidden"
  | "validation_error"
  | "conflict"
  | "listing_not_available"
  | "invalid_state"
  | "payment_pending"
  | "provider_unavailable"
  | "rate_limited"
  | "internal_error";

const STATUS: Record<ErrorCode, number> = {
  unauthenticated: 401,
  forbidden: 403,
  validation_error: 422,
  conflict: 409,
  listing_not_available: 409,
  invalid_state: 409,
  payment_pending: 409,
  provider_unavailable: 503,
  rate_limited: 429,
  internal_error: 500,
};

export class AppError extends Error {
  constructor(
    readonly code: ErrorCode,
    message: string,
    readonly details: Record<string, unknown> = {},
  ) {
    super(message);
  }
}

// Browser callers (Flutter Web) need CORS. Restrict ALLOWED_ORIGINS in
// staging/production; "*" is only the local default.
const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ?? "*").split(",");

function corsHeaders(req: Request): Record<string, string> {
  const origin = req.headers.get("origin") ?? "";
  const allow = ALLOWED_ORIGINS.includes("*")
    ? "*"
    : ALLOWED_ORIGINS.includes(origin)
    ? origin
    : ALLOWED_ORIGINS[0];
  return {
    "access-control-allow-origin": allow,
    "access-control-allow-headers":
      "authorization, x-client-info, apikey, content-type",
    "access-control-allow-methods": "POST, OPTIONS",
    "vary": "origin",
  };
}

function json(req: Request, body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders(req),
      "content-type": "application/json; charset=utf-8",
    },
  });
}

export function ok(req: Request, data: unknown, requestId: string): Response {
  return json(req, { data, requestId }, 200);
}

export function fail(req: Request, err: unknown, requestId: string): Response {
  const e = err instanceof AppError
    ? err
    : new AppError("internal_error", "Unexpected error");
  // Never leak internal messages, secrets or provider payloads to clients.
  if (!(err instanceof AppError)) console.error({ requestId, err });
  return json(req, {
    error: { code: e.code, message: e.message, details: e.details },
    requestId,
  }, STATUS[e.code]);
}

/** Wraps a handler with CORS preflight, request id and error mapping. */
export function handler(
  fn: (req: Request, requestId: string) => Promise<unknown>,
): (req: Request) => Promise<Response> {
  return async (req) => {
    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(req) });
    }
    const requestId = crypto.randomUUID();
    try {
      return ok(req, await fn(req, requestId), requestId);
    } catch (err) {
      return fail(req, err, requestId);
    }
  };
}

export async function readJson<T>(req: Request): Promise<T> {
  try {
    return await req.json() as T;
  } catch {
    throw new AppError("validation_error", "Invalid JSON body");
  }
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function requireUuid(value: unknown, field: string): string {
  if (typeof value !== "string" || !UUID_RE.test(value)) {
    throw new AppError("validation_error", `${field} must be a UUID`, {
      field,
    });
  }
  return value;
}
