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

const JSON_HEADERS = { "content-type": "application/json; charset=utf-8" };

export function ok(data: unknown, requestId: string): Response {
  return new Response(JSON.stringify({ data, requestId }), {
    status: 200,
    headers: JSON_HEADERS,
  });
}

export function fail(err: unknown, requestId: string): Response {
  const e = err instanceof AppError
    ? err
    : new AppError("internal_error", "Unexpected error");
  // Never leak internal messages, secrets or provider payloads to clients.
  if (!(err instanceof AppError)) console.error({ requestId, err });
  return new Response(
    JSON.stringify({
      error: { code: e.code, message: e.message, details: e.details },
      requestId,
    }),
    { status: STATUS[e.code], headers: JSON_HEADERS },
  );
}

/** Wraps a handler with request id + error mapping. */
export function handler(
  fn: (req: Request, requestId: string) => Promise<unknown>,
): (req: Request) => Promise<Response> {
  return async (req) => {
    const requestId = crypto.randomUUID();
    try {
      return ok(await fn(req, requestId), requestId);
    } catch (err) {
      return fail(err, requestId);
    }
  };
}
