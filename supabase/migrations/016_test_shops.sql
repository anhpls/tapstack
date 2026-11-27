-- test shops let one account be both customer and staff (for solo testing)
alter table shops add column is_test boolean not null default false;

-- mark the sample shops as test shops
update shops set is_test = true;

-- give_stamps: self-stamping allowed only at test shops
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
begin
  select * into v_card from memberships where member_number = p_member_number;
  if not found then raise exception 'No card with that number.'; end if;

  if not exists (select 1 from shop_members
                 where shop_id = v_card.shop_id and user_id = auth.uid()) then
    raise exception 'You are not staff at this shop.';
  end if;

  if v_card.user_id = auth.uid()
     and not (select is_test from shops where id = v_card.shop_id) then
    raise exception 'You can''t stamp your own card.';
  end if;

  select max_stamps_per_visit into v_max from stamp_programs where shop_id = v_card.shop_id;
  if p_count < 1 or p_count > v_max then
    raise exception 'You can give 1 to % stamps per visit.', v_max;
  end if;

  if exists (select 1 from stamps
             where membership_id = v_card.id
               and reason <> 'correction'
               and created_at > now() - interval '2 minutes') then
    raise exception 'This card was just stamped. Try again in a couple of minutes.';
  end if;

  select coalesce(max(multiplier), 1) into v_multiplier from stamp_promos
   where shop_id = v_card.shop_id and now() between starts_at and ends_at;
  v_bonus := p_count * (v_multiplier - 1);

  insert into stamps (membership_id, given_by, visit_id, reason)
  select v_card.id, auth.uid(), v_visit, 'purchase' from generate_series(1, p_count);

  if v_bonus > 0 then
    insert into stamps (membership_id, given_by, visit_id, reason)
    select v_card.id, auth.uid(), v_visit, 'promo' from generate_series(1, v_bonus);
  end if;

  return balance(v_card);
end;
$$;

-- redeem_reward: self-redeeming allowed only at test shops
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

  if v_card.user_id = auth.uid()
     and not (select is_test from shops where id = v_card.shop_id) then
    raise exception 'You can''t redeem your own card.';
  end if;

  select stamps_needed, reward into v_needed, v_reward
    from stamp_programs where shop_id = v_card.shop_id;

  if balance(v_card) < v_needed then
    raise exception 'Not enough stamps yet: % of %.', balance(v_card), v_needed;
  end if;

  insert into redemptions (membership_id, redeemed_by, stamps_used, reward)
  values (v_card.id, auth.uid(), v_needed, v_reward);

  update redemption_requests set status = 'redeemed'
   where membership_id = v_card.id and status = 'pending' and expires_at > now();

  return balance(v_card);
end;
$$;

-- complete_transfer (self-verifying at test shops) is redefined in 017
