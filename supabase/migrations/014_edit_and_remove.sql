-- shape of the back image, so swapping sides never stretches it
alter table personal_cards add column image_back_aspect real;

-- let people delete their own card photos
create policy "delete own card images" on storage.objects for delete to authenticated
  using (bucket_id = 'card-images' and (storage.foldername(name))[1] = auth.uid()::text);

-- hide Tapstack cards instead of deleting (keeps the shop's records)
alter table memberships add column hidden_at timestamptz;

create or replace function hide_membership(p_membership_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update memberships set hidden_at = now()
   where id = p_membership_id and user_id = auth.uid();
  if not found then raise exception 'Card not found.'; end if;
end;
$$;

-- joining again brings a hidden card back (with its stamps)
create or replace function join_shop(p_shop_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into memberships (user_id, shop_id) values (auth.uid(), p_shop_id)
  on conflict (user_id, shop_id) do update set hidden_at = null;
end;
$$;

revoke all on function hide_membership(uuid) from public;
revoke all on function join_shop(uuid) from public;
grant execute on function hide_membership(uuid) to authenticated;
grant execute on function join_shop(uuid) to authenticated;
