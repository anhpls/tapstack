-- a personal card that has been moved into a real membership
alter table personal_cards add column transferred_at timestamptz;

create table transfer_requests (
  id uuid primary key default gen_random_uuid(),
  personal_card_id uuid references personal_cards on delete cascade not null,
  shop_id uuid references shops on delete cascade not null,
  user_id uuid references auth.users on delete cascade not null default auth.uid(),
  claimed_stamps int not null,
  code text not null,
  status text not null default 'pending' check (status in ('pending', 'completed', 'cancelled')),
  expires_at timestamptz not null default now() + interval '10 minutes',
  created_at timestamptz default now()
);
alter table transfer_requests enable row level security;

create policy "see own transfers" on transfer_requests for select using (auth.uid() = user_id);
create policy "staff see shop transfers" on transfer_requests for select using (
  exists (select 1 from shop_members sm where sm.shop_id = transfer_requests.shop_id and sm.user_id = auth.uid())
);

-- customer: "verify my paper card at this shop" → returns a code
create or replace function request_transfer(p_personal_card_id uuid, p_shop_id uuid)
returns table (id uuid, code text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card personal_cards%rowtype;
begin
  select * into v_card from personal_cards pc
   where pc.id = p_personal_card_id and pc.user_id = auth.uid() and pc.transferred_at is null;
  if not found then raise exception 'Card not found.'; end if;

  if not exists (select 1 from shops s where s.id = p_shop_id) then
    raise exception 'Shop not found.';
  end if;

  update transfer_requests t set status = 'cancelled'
   where t.personal_card_id = v_card.id and t.status = 'pending';

  return query
    insert into transfer_requests (personal_card_id, shop_id, claimed_stamps, code)
    values (v_card.id, p_shop_id, v_card.pending_stamps, lpad(floor(random() * 10000)::text, 4, '0'))
    returning transfer_requests.id, transfer_requests.code;
end;
$$;

-- staff: confirm the stamps they actually see on the paper card
create or replace function complete_transfer(p_code text, p_shop_id uuid, p_confirmed int)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_req transfer_requests%rowtype;
  v_membership memberships%rowtype;
begin
  if not exists (select 1 from shop_members
                 where shop_id = p_shop_id and user_id = auth.uid()) then
    raise exception 'You are not staff at this shop.';
  end if;

  select * into v_req from transfer_requests
   where code = p_code and shop_id = p_shop_id
     and status = 'pending' and expires_at > now()
   order by created_at desc limit 1;
  if not found then raise exception 'No transfer with that code. It may have expired.'; end if;

  if v_req.user_id = auth.uid() then
    raise exception 'You can''t verify your own card.';
  end if;

  -- staff can confirm fewer stamps than claimed, never more
  if p_confirmed < 0 or p_confirmed > v_req.claimed_stamps then
    raise exception 'Confirm between 0 and % stamps.', v_req.claimed_stamps;
  end if;

  -- create (or bring back) the customer's real membership
  insert into memberships (user_id, shop_id) values (v_req.user_id, p_shop_id)
  on conflict (user_id, shop_id) do update set hidden_at = null
  returning * into v_membership;

  if p_confirmed > 0 then
    insert into stamps (membership_id, given_by, reason)
    select v_membership.id, auth.uid(), 'transfer' from generate_series(1, p_confirmed);
  end if;

  update transfer_requests set status = 'completed' where id = v_req.id;
  update personal_cards set transferred_at = now() where id = v_req.personal_card_id;

  return balance(v_membership);
end;
$$;

revoke all on function request_transfer(uuid, uuid) from public;
revoke all on function complete_transfer(text, uuid, int) from public;
grant execute on function request_transfer(uuid, uuid) to authenticated;
grant execute on function complete_transfer(text, uuid, int) to authenticated;
