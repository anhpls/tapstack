-- staff can see the cards and stamps at shops they work at
create policy "staff see shop memberships" on memberships for select using (
  exists (select 1 from shop_members sm
          where sm.shop_id = memberships.shop_id and sm.user_id = auth.uid())
);

create policy "staff see shop stamps" on stamps for select using (
  exists (select 1 from memberships m
          join shop_members sm on sm.shop_id = m.shop_id
          where m.id = stamps.membership_id and sm.user_id = auth.uid())
);

-- the ONLY way to add a stamp: a function that checks the rules first
create or replace function give_stamp(p_member_number text)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card memberships%rowtype;
  v_recent int;
  v_total int;
begin
  select * into v_card from memberships where member_number = p_member_number;
  if not found then
    raise exception 'No card with that number.';
  end if;

  -- rule 1: you must work at this shop
  if not exists (select 1 from shop_members
                 where shop_id = v_card.shop_id and user_id = auth.uid()) then
    raise exception 'You are not staff at this shop.';
  end if;

  -- rule 2: staff can't stamp their own card
  if v_card.user_id = auth.uid() then
    raise exception 'You can''t stamp your own card.';
  end if;

  -- rule 3: one stamp per card every 2 minutes (stops double taps)
  select count(*) into v_recent from stamps
   where membership_id = v_card.id and created_at > now() - interval '2 minutes';
  if v_recent > 0 then
    raise exception 'This card was just stamped. Try again in a couple of minutes.';
  end if;

  insert into stamps (membership_id, given_by) values (v_card.id, auth.uid());
  select count(*) into v_total from stamps where membership_id = v_card.id;
  return v_total;
end;
$$;

revoke all on function give_stamp(text) from public;
grant execute on function give_stamp(text) to authenticated;
