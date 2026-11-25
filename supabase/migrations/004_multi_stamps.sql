-- each shop decides its own per-visit limit
alter table stamp_programs
  add column max_stamps_per_visit int not null default 5
  check (max_stamps_per_visit between 1 and 20);

-- why each stamp was given, and which visit it belongs to
alter table stamps
  add column visit_id uuid,
  add column reason text not null default 'purchase'
  check (reason in ('purchase', 'promo', 'transfer', 'correction'));

-- shop promos like "double stamps this weekend"
create table stamp_promos (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid references shops on delete cascade not null,
  name text not null,
  multiplier int not null default 2 check (multiplier between 2 and 5),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  check (ends_at > starts_at)
);
alter table stamp_promos enable row level security;
create policy "anyone can view promos" on stamp_promos for select using (true);

-- replace the old one-stamp function
drop function if exists give_stamp(text);

create or replace function give_stamps(p_member_number text, p_count int default 1)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card memberships%rowtype;
  v_max int;
  v_multiplier int;
  v_bonus int;
  v_visit uuid := gen_random_uuid();
  v_total int;
begin
  select * into v_card from memberships where member_number = p_member_number;
  if not found then raise exception 'No card with that number.'; end if;

  if not exists (select 1 from shop_members
                 where shop_id = v_card.shop_id and user_id = auth.uid()) then
    raise exception 'You are not staff at this shop.';
  end if;

  if v_card.user_id = auth.uid() then
    raise exception 'You can''t stamp your own card.';
  end if;

  -- per-visit limit set by the shop
  select max_stamps_per_visit into v_max from stamp_programs where shop_id = v_card.shop_id;
  if p_count < 1 or p_count > v_max then
    raise exception 'You can give 1 to % stamps per visit.', v_max;
  end if;

  -- one transaction per card every 2 minutes
  if exists (select 1 from stamps
             where membership_id = v_card.id and created_at > now() - interval '2 minutes') then
    raise exception 'This card was just stamped. Try again in a couple of minutes.';
  end if;

  -- active promo? (if several, use the biggest)
  select coalesce(max(multiplier), 1) into v_multiplier from stamp_promos
   where shop_id = v_card.shop_id and now() between starts_at and ends_at;
  v_bonus := p_count * (v_multiplier - 1);

  -- purchase stamps
  insert into stamps (membership_id, given_by, visit_id, reason)
  select v_card.id, auth.uid(), v_visit, 'purchase' from generate_series(1, p_count);

  -- promo bonus stamps (only if a promo is running)
  if v_bonus > 0 then
    insert into stamps (membership_id, given_by, visit_id, reason)
    select v_card.id, auth.uid(), v_visit, 'promo' from generate_series(1, v_bonus);
  end if;

  select count(*) into v_total from stamps where membership_id = v_card.id;
  return v_total;
end;
$$;

revoke all on function give_stamps(text, int) from public;
grant execute on function give_stamps(text, int) to authenticated;
