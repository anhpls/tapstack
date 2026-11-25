-- SHOPS: every business on Tapstack
create table shops (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null check (category in ('cafe','boba','restaurant','bakery')),
  color_hex text not null default '#5B7DB1',
  created_at timestamptz default now()
);

-- SHOP_MEMBERS: who can use Business mode for a shop, and their role
create table shop_members (
  shop_id uuid references shops on delete cascade,
  user_id uuid references auth.users on delete cascade,
  role text not null check (role in ('owner','manager','staff')),
  primary key (shop_id, user_id)
);

-- STAMP_PROGRAMS: each shop's rules ("10 stamps = free drink")
create table stamp_programs (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid references shops on delete cascade not null,
  stamps_needed int not null check (stamps_needed > 0),
  reward text not null
);

-- MEMBERSHIPS: a customer's card at a shop
create table memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null,
  shop_id uuid references shops on delete cascade not null,
  member_number text unique not null,
  created_at timestamptz default now(),
  unique (user_id, shop_id)               -- one card per shop per person
);

-- STAMPS: one row per stamp, logged with who gave it
create table stamps (
  id uuid primary key default gen_random_uuid(),
  membership_id uuid references memberships on delete cascade not null,
  given_by uuid references auth.users,
  created_at timestamptz default now()
);

-- SECURITY: lock every table, then open only what's needed
alter table shops          enable row level security;
alter table shop_members   enable row level security;
alter table stamp_programs enable row level security;
alter table memberships    enable row level security;
alter table stamps         enable row level security;

create policy "anyone can view shops"    on shops          for select using (true);
create policy "anyone can view programs" on stamp_programs for select using (true);
create policy "see own shop roles"       on shop_members   for select using (auth.uid() = user_id);
create policy "see own memberships"      on memberships    for select using (auth.uid() = user_id);
create policy "join a shop"              on memberships    for insert with check (auth.uid() = user_id);
create policy "see own stamps"           on stamps         for select using (
  exists (select 1 from memberships m where m.id = membership_id and m.user_id = auth.uid())
);
