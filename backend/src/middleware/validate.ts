/**
 * Zod-backed request validation.
 *
 * Parses body/query/params against a schema and REPLACES the request property
 * with the parsed, typed, coerced value. Handlers downstream then work with
 * validated data and never re-check it. A parse failure throws a ZodError,
 * which the error handler renders as a 400 with field-level detail.
 */

import type { NextFunction, Request, Response } from 'express';
import type { ZodTypeAny, z } from 'zod';

type Part = 'body' | 'query' | 'params';

export function validate<S extends ZodTypeAny>(part: Part, schema: S) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req[part]);
    if (!result.success) {
      return next(result.error);
    }
    // Query and params are read-only getters on some Express versions; assign
    // through a cast so the parsed value is what handlers see.
    (req as unknown as Record<Part, unknown>)[part] = result.data;
    next();
  };
}

/** Helper to read a validated part with its inferred type inside a handler. */
export function validated<S extends ZodTypeAny>(req: Request, part: Part): z.infer<S> {
  return req[part] as z.infer<S>;
}
