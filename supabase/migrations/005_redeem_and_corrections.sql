-- +1 for a normal stamp, -1 for a correction
alter table stamps
  add column amount int not null default 1 check (amount in (1, -1));

-- one row each time a reward is redeemed
create table redemptions (
  id uuid primary key default gen_random_uuid(),
  membership_id uuid references memberships on delete cascade not null,
  redeemed_by uuid references auth.users,
  stamps_used int not null check (stamps_used > 0),
  reward text not null,
  created_at timestamptz default now()
);
alter table redemptions enable row level security;

create policy "see own redemptions" on redemptions for select using (
  exists (select 1 from memberships m where m.id = membership_id and m.user_id = auth.uid())
);
create policy "staff see shop redemptions" on redemptions for select using (
  exists (select 1 from memberships m
          join shop_members sm on sm.shop_id = m.shop_id
          where m.id = membership_id and sm.user_id = auth.uid())
);

-- a card's live balance; the app can select it like a column
create or replace function balance(m memberships)
returns int
language sql stable
as $$
  select coalesce((select sum(amount) from stamps where membership_id = m.id), 0)::int
       - coalesce((select sum(stamps_used) from redemptions where membership_id = m.id), 0)::int
$$;

-- staff redeem a reward (needs enough stamps; extras carry over)
create or replace function redeem_reward(p_member_number text)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card memberships%rowtype;
  v_needed int;
  v_reward text;
  v_balance int;
begin
  select * into v_card from memberships where member_number = p_member_number;
  if not found then raise exception 'No card with that number.'; end if;

  if not exists (select 1 from shop_members
                 where shop_id = v_card.shop_id and user_id = auth.uid()) then
    raise exception 'You are not staff at this shop.';
  end if;

  if v_card.user_id = auth.uid() then
    raise exception 'You can''t redeem your own card.';
  end if;

  select stamps_needed, reward into v_needed, v_reward
    from stamp_programs where shop_id = v_card.shop_id;

  v_balance := balance(v_card);
  if v_balance < v_needed then
    raise exception 'Not enough stamps yet: % of %.', v_balance, v_needed;
  end if;

  insert into redemptions (membership_id, redeemed_by, stamps_used, reward)
  values (v_card.id, auth.uid(), v_needed, v_reward);

  return balance(v_card);     -- the carried-over stamps
end;
$$;

-- owners/managers fix a mistake by adding a -1 entry (never deleting)
create or replace function remove_stamp(p_member_number text)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card memberships%rowtype;
begin
  select * into v_card from memberships where member_number = p_member_number;
  if not found then raise exception 'No card with that number.'; end if;

  if not exists (select 1 from shop_members
                 where shop_id = v_card.shop_id and user_id = auth.uid()
                   and role in ('owner', 'manager')) then
    raise exception 'Only owners and managers can remove stamps.';
  end if;

  if balance(v_card) < 1 then
    raise exception 'This card has no stamps to remove.';
  end if;

  insert into stamps (membership_id, given_by, reason, amount)
  values (v_card.id, auth.uid(), 'correction', -1);

  return balance(v_card);
end;
$$;

revoke all on function redeem_reward(text) from public;
revoke all on function remove_stamp(text)  from public;
grant execute on function redeem_reward(text) to authenticated;
grant execute on function remove_stamp(text)  to authenticated;
