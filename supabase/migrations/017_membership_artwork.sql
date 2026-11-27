-- a membership can keep the artwork from the customer's scanned paper card
alter table memberships
  add column card_image_path text,
  add column card_back_image_path text,
  add column card_image_aspect real;

-- same as before, plus: copy the scanned artwork onto the new membership
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

  if v_req.user_id = auth.uid()
     and not (select is_test from shops where id = p_shop_id) then
    raise exception 'You can''t verify your own card.';
  end if;

  if p_confirmed < 0 or p_confirmed > v_req.claimed_stamps then
    raise exception 'Confirm between 0 and % stamps.', v_req.claimed_stamps;
  end if;

  insert into memberships (user_id, shop_id) values (v_req.user_id, p_shop_id)
  on conflict (user_id, shop_id) do update set hidden_at = null
  returning * into v_membership;

  -- NEW: keep the customer's scanned artwork on their official card
  update memberships m
     set card_image_path      = pc.image_path,
         card_back_image_path = pc.image_back_path,
         card_image_aspect    = pc.image_aspect
    from personal_cards pc
   where pc.id = v_req.personal_card_id and m.id = v_membership.id;

  if p_confirmed > 0 then
    insert into stamps (membership_id, given_by, reason)
    select v_membership.id, auth.uid(), 'transfer' from generate_series(1, p_confirmed);
  end if;

  update transfer_requests set status = 'completed' where id = v_req.id;
  update personal_cards set transferred_at = now() where id = v_req.personal_card_id;

  return balance(v_membership);
end;
$$;
