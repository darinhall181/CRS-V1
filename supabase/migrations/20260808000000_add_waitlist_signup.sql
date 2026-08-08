-- waitlist_signup: landing-page email capture (see www/src/app/api/waitlist/route.ts).
-- Backfilled after the fact — this table was pushed to Neon directly via
-- `drizzle-kit push` on main without a committed migration; this file brings
-- the migration history in line with what's already live.

create table waitlist_signup (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  source text default 'landing',
  referrer text,
  created_at timestamptz not null default now()
);

create index waitlist_signup_created_at_idx on waitlist_signup (created_at);
