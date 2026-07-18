-- 0003_giving.sql
-- Contribution categories, contribution batches, and their per-category splits.

-- ---------------------------------------------------------------------------
-- contribution_categories
-- ---------------------------------------------------------------------------
-- Driven from the database so the category list can change (new appeals, new
-- conference drives) without an app release. church_id null => global category
-- offered to every congregation; non-null => that church only.
create table public.contribution_categories (
  id           uuid primary key default gen_random_uuid(),
  church_id    uuid references public.churches (id) on delete cascade,
  code         text not null,
  name         text not null,
  description  text,
  -- Drives the row colour in the Bahasha home list.
  color_hex    text not null default '#89D385',
  sort_order   integer not null default 0,
  -- Categories with a mandated amount (e.g. Station Fund, KSh 200). When set,
  -- the app presents the amount read-only.
  fixed_amount numeric(12, 2),
  -- Categories expressed as a share of income (e.g. God's Tithe, 10%). Used
  -- only to prefill a suggestion; the giver always confirms the final figure.
  percentage_hint numeric(5, 2),
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),

  constraint categories_code_format check (code ~ '^[a-z0-9]+(_[a-z0-9]+)*$'),
  constraint categories_name_not_blank check (length(btrim(name)) > 0),
  constraint categories_color_hex_format check (color_hex ~* '^#[0-9a-f]{6}$'),
  constraint categories_fixed_amount_positive check (
    fixed_amount is null or fixed_amount > 0
  ),
  constraint categories_percentage_hint_range check (
    percentage_hint is null or (percentage_hint > 0 and percentage_hint <= 100)
  ),
  -- A category is either a fixed amount or a percentage, never both.
  constraint categories_fixed_xor_percentage check (
    fixed_amount is null or percentage_hint is null
  )
);

-- Codes are unique per church, and unique among globals. Two partial indexes
-- because null church_id does not collide under a plain unique index.
create unique index categories_code_global_key
  on public.contribution_categories (code) where church_id is null;
create unique index categories_code_church_key
  on public.contribution_categories (church_id, code) where church_id is not null;
create index categories_active_sort_idx
  on public.contribution_categories (sort_order) where is_active;

create trigger categories_set_updated_at
  before update on public.contribution_categories
  for each row execute function public.tg_set_updated_at();

-- ---------------------------------------------------------------------------
-- contributions
-- ---------------------------------------------------------------------------
-- One giving action by one person: a basket of category allocations settled by
-- a single STK Push. Created from a verified BLE payload, never directly.
create table public.contributions (
  id                 uuid primary key default gen_random_uuid(),
  -- The UUID minted on the giver's device and carried in the BLE payload.
  -- This is the idempotency key for the whole pipeline: a hub may upload the
  -- same packet twice (retry, duplicate scan) and must not double-charge.
  client_uuid        uuid not null,
  user_id            uuid not null references public.users (id) on delete restrict,
  church_id          uuid not null references public.churches (id) on delete restrict,
  device_id          uuid not null references public.devices (id) on delete restrict,
  hub_id             uuid,  -- FK added in 0004, after church_hubs exists.
  total_amount       numeric(12, 2) not null,
  status             contribution_status not null default 'pending',
  -- Frozen copy of users.visibility at the moment of giving. Analytics reads
  -- this, so a later switch to "Give Openly" cannot expose past secret giving
  -- (and vice versa).
  visibility_snapshot giving_visibility not null,
  -- Clock on the giver's device when the payload was built. Trusted only for
  -- display and staleness checks, never for ordering or replay defence.
  device_timestamp   timestamptz not null,
  received_at        timestamptz not null default now(),
  processed_at       timestamptz,
  failure_reason     text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now(),

  -- Daraja rejects non-positive amounts and caps a single STK Push. The upper
  -- bound is Safaricom's per-transaction ceiling and is asserted here so a
  -- malformed payload fails at the door rather than at the API.
  constraint contributions_total_amount_positive check (total_amount > 0),
  constraint contributions_total_amount_ceiling check (total_amount <= 250000),
  -- STK Push only accepts whole shillings.
  constraint contributions_total_amount_whole check (total_amount = trunc(total_amount)),
  constraint contributions_processed_consistency check (
    (status in ('completed', 'failed', 'cancelled', 'expired')) = (processed_at is not null)
  )
);

-- The idempotency guarantee. Scoped by user so a UUID collision across two
-- devices cannot let one giver's packet suppress another's.
create unique index contributions_client_uuid_key
  on public.contributions (user_id, client_uuid);
create index contributions_church_received_idx
  on public.contributions (church_id, received_at desc);
create index contributions_user_received_idx
  on public.contributions (user_id, received_at desc);
create index contributions_status_idx
  on public.contributions (status) where status in ('pending', 'processing');
-- Serves the dashboard's anonymous-vs-open breakdown without a table scan.
create index contributions_church_visibility_idx
  on public.contributions (church_id, visibility_snapshot, received_at desc);

create trigger contributions_set_updated_at
  before update on public.contributions
  for each row execute function public.tg_set_updated_at();

-- ---------------------------------------------------------------------------
-- contribution_allocations
-- ---------------------------------------------------------------------------
-- The line items: "Tithe 1000, Mission 500, Building 200" for a 1700 batch.
create table public.contribution_allocations (
  id              uuid primary key default gen_random_uuid(),
  contribution_id uuid not null references public.contributions (id) on delete cascade,
  category_id     uuid not null references public.contribution_categories (id) on delete restrict,
  amount          numeric(12, 2) not null,
  created_at      timestamptz not null default now(),

  constraint allocations_amount_positive check (amount > 0),
  constraint allocations_amount_whole check (amount = trunc(amount))
);

-- A category may appear at most once per contribution; two "Tithe" lines are a
-- client bug, and silently summing them would corrupt the category reports.
create unique index allocations_contribution_category_key
  on public.contribution_allocations (contribution_id, category_id);
create index allocations_contribution_idx
  on public.contribution_allocations (contribution_id);
create index allocations_category_idx
  on public.contribution_allocations (category_id);

-- ---------------------------------------------------------------------------
-- Integrity: allocations must sum to the batch total
-- ---------------------------------------------------------------------------
-- If these ever drift, the church is charged one figure and credited another --
-- the single worst bug this system could have. A deferred constraint trigger
-- lets the API insert the parent and its children in one transaction and still
-- asserts the invariant before commit.
create or replace function public.tg_assert_allocation_sum()
returns trigger
language plpgsql
as $$
declare
  v_contribution_id uuid := coalesce(new.contribution_id, old.contribution_id);
  v_total    numeric(12, 2);
  v_declared numeric(12, 2);
begin
  select total_amount into v_declared
    from public.contributions
   where id = v_contribution_id;

  -- Parent already gone (cascade delete): nothing left to assert.
  if not found then
    return null;
  end if;

  select coalesce(sum(amount), 0) into v_total
    from public.contribution_allocations
   where contribution_id = v_contribution_id;

  if v_total <> v_declared then
    -- RAISE has no printf precision specifiers: % is the placeholder and any
    -- trailing format text would print literally. numeric(12,2) already
    -- renders to two decimal places.
    raise exception
      'allocation sum % does not match contribution total % for contribution %',
      v_total, v_declared, v_contribution_id
      using errcode = 'check_violation';
  end if;

  return null;
end;
$$;

create constraint trigger allocations_sum_matches_total
  after insert or update or delete on public.contribution_allocations
  deferrable initially deferred
  for each row execute function public.tg_assert_allocation_sum();

-- The same invariant from the parent side: catches a total_amount edited after
-- the allocations were written. Separate function because the row fired from
-- contributions exposes the id as NEW.id, not NEW.contribution_id.
create or replace function public.tg_assert_allocation_sum_for_parent()
returns trigger
language plpgsql
as $$
declare
  v_total numeric(12, 2);
begin
  select coalesce(sum(amount), 0) into v_total
    from public.contribution_allocations
   where contribution_id = new.id;

  -- A contribution with no allocations yet is legal mid-transaction; the
  -- child-side deferred trigger asserts the sum once the lines land. Skip
  -- rather than fail, otherwise inserting the parent first is impossible.
  if v_total = 0 then
    return null;
  end if;

  if v_total <> new.total_amount then
    raise exception
      'contribution % total % does not match allocation sum %',
      new.id, new.total_amount, v_total
      using errcode = 'check_violation';
  end if;

  return null;
end;
$$;

create constraint trigger contributions_total_matches_allocations
  after update of total_amount on public.contributions
  deferrable initially deferred
  for each row execute function public.tg_assert_allocation_sum_for_parent();
