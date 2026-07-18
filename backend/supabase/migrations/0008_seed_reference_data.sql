-- 0008_seed_reference_data.sql
-- Reference data: the launch churches and the global contribution categories.
--
-- Idempotent: safe to re-run on every deploy. Categories upsert on their code
-- so copy edits ship by re-running the migration rather than by hand-editing
-- production rows.
--
-- NOTE ON SHORTCODES: these churches are seeded with mpesa_shortcode = null on
-- purpose. The trigger in 0004 refuses to create a transaction for a church
-- with no shortcode, so a fresh environment physically cannot move money until
-- an operator sets each church's real paybill. Do not seed a placeholder here.

-- ---------------------------------------------------------------------------
-- Launch churches
-- ---------------------------------------------------------------------------
insert into public.churches (name, slug, city, county, is_active) values
  ('Zetech University SDA Church',        'zetech-university-sda',        'Ruiru',   'Kiambu',  true),
  ('Jomo Kenyatta University SDA Church', 'jkuat-sda',                    'Juja',    'Kiambu',  true),
  ('Kenyatta University SDA Church',      'kenyatta-university-sda',      'Kahawa',  'Nairobi', true),
  ('KCA University SDA Church',           'kca-university-sda',           'Ruaraka', 'Nairobi', true)
on conflict (slug) do update
  set name      = excluded.name,
      city      = excluded.city,
      county    = excluded.county,
      is_active = excluded.is_active;

-- ---------------------------------------------------------------------------
-- Global contribution categories
-- ---------------------------------------------------------------------------
-- Colours cycle the Bahasha Figma palette: #D1EFBD, #89D385, #6CD1F0, #A1A1F7.
-- sort_order is spaced by 10 so a category can be slotted between two others
-- later without renumbering the set.
insert into public.contribution_categories
  (church_id, code, name, description, color_hex, sort_order, fixed_amount, percentage_hint)
values
  (null, 'tithe', 'God''s Tithe',
   'Your contributions support your local conference pastors and church conference workers',
   '#D1EFBD', 10, null, 10.00),

  (null, 'combined_offering', 'Combined Offering',
   'Shared offering distributed across local, conference and union funds',
   '#89D385', 20, null, null),

  (null, 'local_church_budget', 'Local Church Budget (LCB) / AEMR',
   'Runs the day-to-day operations of your local church',
   '#6CD1F0', 30, null, null),

  (null, 'church_building', 'Church Building / Development',
   'Construction and development of your local church',
   '#A1A1F7', 40, null, null),

  (null, 'church_evangelism', 'Church Evangelism',
   'Supports evangelism run by your local church',
   '#D1EFBD', 50, null, null),

  (null, 'conference_evangelism', 'Conference Evangelism',
   'Supports evangelism coordinated at conference level',
   '#89D385', 60, null, null),

  (null, 'camp_meeting_offering', 'Camp Meeting Offering',
   'Offering collected toward camp meeting',
   '#6CD1F0', 70, null, null),

  (null, 'camp_meeting_expenses', 'Camp Meeting Expenses',
   'Covers the running costs of camp meeting',
   '#A1A1F7', 80, null, null),

  (null, 'thanksgiving', 'Thanksgiving',
   'A thanksgiving offering',
   '#D1EFBD', 90, null, null),

  (null, 'welfare', 'Welfare',
   'Supports members of the church family in need',
   '#89D385', 100, null, null),

  (null, 'station_fund', 'Station Fund',
   'Fixed station contribution of KSh 200',
   '#6CD1F0', 110, 200.00, null),

  (null, 'others', 'Others',
   'Any other contribution not covered above',
   '#A1A1F7', 120, null, null)
on conflict (code) where church_id is null do update
  set name            = excluded.name,
      description     = excluded.description,
      color_hex       = excluded.color_hex,
      sort_order      = excluded.sort_order,
      fixed_amount    = excluded.fixed_amount,
      percentage_hint = excluded.percentage_hint,
      is_active       = true;
