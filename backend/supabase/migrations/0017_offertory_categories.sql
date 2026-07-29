-- 0017_offertory_categories.sql
-- Reference categories for the offertory (fruit) redesign of the Bahasha app.
--
-- The mobile app now shows ten fruit-represented giving types; their codes must
-- exist here or the ingest RPC rejects the contribution ("unknown contribution
-- category"). This is reference DATA only — no backend logic changes. Existing
-- categories are left in place; these are added idempotently as global rows
-- (church_id null). 'tithe' already exists from the launch seed.

insert into public.contribution_categories (church_id, code, name, description, color_hex, sort_order, percentage_hint)
select v.church_id, v.code, v.name, v.description, v.color_hex, v.sort_order, v.percentage_hint
from (values
  (null::uuid, 'offering',          'Offering',          'General offering',                     '#E03131', 20, null::numeric),
  (null::uuid, 'church_budget',     'Church budget',     'Runs the local church',                '#8B5CF6', 21, null::numeric),
  (null::uuid, 'camp_offering',     'Camp offering',     'Offering toward camp meeting',         '#E8A13A', 22, null::numeric),
  (null::uuid, 'camp_budget',       'Camp budget',       'Camp meeting running costs',           '#F59E0B', 23, null::numeric),
  (null::uuid, 'mission',           'Mission',           'Supports mission work',                '#10B981', 24, null::numeric),
  (null::uuid, 'development',       'Development',       'Church building and development',      '#6D4AFF', 25, null::numeric),
  (null::uuid, 'children_ministry', 'Children ministry', 'Supports the children''s ministry',    '#EC4899', 26, null::numeric),
  (null::uuid, 'women_ministry',    'Women ministry',    'Supports the women''s ministry',       '#14B8A6', 27, null::numeric),
  (null::uuid, 'adventist_men',     'Adventist men',     'Supports the Adventist men''s ministry', '#3B82F6', 28, null::numeric)
) as v(church_id, code, name, description, color_hex, sort_order, percentage_hint)
where not exists (
  select 1 from public.contribution_categories c
  where c.code = v.code and c.church_id is null
);
