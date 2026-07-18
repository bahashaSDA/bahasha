/**
 * Public reference data: the church list and the contribution categories.
 *
 * Unauthenticated on purpose. The mobile apps fetch both at first launch,
 * before anyone has registered, so new churches and new categories roll out
 * without an app release. Only non-sensitive columns are returned (no
 * shortcodes, no api keys) -- the RLS column grants in 0007 enforce the same
 * thing at the database, this is defence in depth at the API.
 */

import { Router } from 'express';
import { adminDb } from '../lib/supabase.js';
import { asyncHandler } from '../middleware/async-handler.js';
import { notFound } from '../lib/errors.js';

export const churchesRouter = Router();

churchesRouter.get(
  '/churches',
  asyncHandler(async (_req, res) => {
    const { data, error } = await adminDb
      .from('churches')
      .select('id, name, slug, city, county, latitude, longitude, public_key')
      .eq('is_active', true)
      .order('name');
    if (error) throw error;
    res.json({ churches: data ?? [] });
  }),
);

churchesRouter.get(
  '/churches/:id/categories',
  asyncHandler(async (req, res) => {
    const churchId = req.params.id;

    const { data: church } = await adminDb
      .from('churches')
      .select('id')
      .eq('id', churchId)
      .eq('is_active', true)
      .maybeSingle();
    if (!church) throw notFound('Church not found');

    // Global categories (church_id is null) plus any specific to this church.
    const { data, error } = await adminDb
      .from('contribution_categories')
      .select('id, church_id, code, name, description, color_hex, sort_order, fixed_amount, percentage_hint')
      .eq('is_active', true)
      .or(`church_id.is.null,church_id.eq.${churchId}`)
      .order('sort_order');
    if (error) throw error;

    res.json({ categories: data ?? [] });
  }),
);

/** Global categories only -- used by the app's first-launch offline cache. */
churchesRouter.get(
  '/categories',
  asyncHandler(async (_req, res) => {
    const { data, error } = await adminDb
      .from('contribution_categories')
      .select('id, code, name, description, color_hex, sort_order, fixed_amount, percentage_hint')
      .is('church_id', null)
      .eq('is_active', true)
      .order('sort_order');
    if (error) throw error;
    res.json({ categories: data ?? [] });
  }),
);
