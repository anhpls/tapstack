create table redemption_requests (
  id uuid primary key default gen_random_uuid(),
  membership_id uuid references memberships on delete cascade not null,
  code text not null,
  status text not null default 'pending' check (status in ('pending', 'redeemed', 'cancelled')),
  expires_at timestamptz not null default now() + interval '5 minutes',
  created_at timestamptz default now()
);
alter table redemption_requests enable row level security;

create policy "see own requests" on redemption_requests for select using (
  exists (select 1 from memberships m where m.id = membership_id and m.user_id = auth.uid())
);
create policy "staff see shop requests" on redemption_requests for select using (
  exists (select 1 from memberships m
          join shop_members sm on sm.shop_id = m.shop_id
          where m.id = membership_id and sm.user_id = auth.uid())
);

-- customer starts a redemption: checks the card is theirs and ready, returns a code
create or replace function request_redemption(p_membership_id uuid)
returns table (id uuid, code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card memberships%rowtype;
  v_needed int;
begin
  select * into v_card from memberships m
   where m.id = p_membership_id and m.user_id = auth.uid();
  if not found then raise exception 'Card not found.'; end if;

  select stamps_needed into v_needed from stamp_programs where shop_id = v_card.shop_id;
  if balance(v_card) < v_needed then
    raise exception 'Not enough stamps yet.';
  end if;

  -- only one live request per card
  update redemption_requests r set status = 'cancelled'
   where r.membership_id = v_card.id and r.status = 'pending';

  return query
    insert into redemption_requests (membership_id, code)
    values (v_card.id, lpad(floor(random() * 10000)::text, 4, '0'))
    returning redemption_requests.id, redemption_requests.code;
end;
$$;

revoke all on function request_redemption(uuid) from public;
grant execute on function request_redemption(uuid) to authenticated;

-- redeem_reward now also marks the customer's request as done
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

  if balance(v_card) < v_needed then
    raise exception 'Not enough stamps yet: % of %.', balance(v_card), v_needed;
  end if;

  insert into redemptions (membership_id, redeemed_by, stamps_used, reward)
  values (v_card.id, auth.uid(), v_needed, v_reward);

  -- NEW: tell the customer's screen it worked
  update redemption_requests set status = 'redeemed'
   where membership_id = v_card.id and status = 'pending' and expires_at > now();

  return balance(v_card);
end;
$$;
