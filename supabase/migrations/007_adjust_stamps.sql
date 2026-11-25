-- 1. replace remove_stamp with a two-way adjustment
drop function if exists remove_stamp(text);

create or replace function adjust_stamps(p_member_number text, p_change int)
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
    raise exception 'Only owners and managers can adjust stamps.';
  end if;

  if p_change = 0 or p_change not between -5 and 5 then
    raise exception 'Adjust by -5 to +5 stamps.';
  end if;

  -- double-tap guard: ignore a second adjustment within 3 seconds
  if exists (select 1 from stamps
             where membership_id = v_card.id and reason = 'correction'
               and given_by = auth.uid()
               and created_at > now() - interval '3 seconds') then
    raise exception 'Adjustment already applied. Wait a moment if you meant to change it again.';
  end if;

  if balance(v_card) + p_change < 0 then
    raise exception 'A card can''t go below 0 stamps.';
  end if;

  -- one row per stamp: +1 rows to add back, -1 rows to remove
  insert into stamps (membership_id, given_by, reason, amount)
  select v_card.id, auth.uid(), 'correction', sign(p_change)::int
  from generate_series(1, abs(p_change));

  return balance(v_card);
end;
$$;

revoke all on function adjust_stamps(text, int) from public;
grant execute on function adjust_stamps(text, int) to authenticated;

-- 2. the 2-minute rule ignores ALL corrections (+ or -), not just removals
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

  if v_card.user_id = auth.uid() then
    raise exception 'You can''t stamp your own card.';
  end if;

  select max_stamps_per_visit into v_max from stamp_programs where shop_id = v_card.shop_id;
  if p_count < 1 or p_count > v_max then
    raise exception 'You can give 1 to % stamps per visit.', v_max;
  end if;

  -- CHANGED: only real visits count, never corrections
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
