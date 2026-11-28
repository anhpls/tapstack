-- owner check, like is_shop_manager
create or replace function is_shop_owner(p_shop_id uuid)
returns boolean language sql stable security invoker set search_path = public as $$
  select exists (select 1 from shop_members
                 where shop_id = p_shop_id and user_id = auth.uid() and role = 'owner');
$$;

-- invites waiting for someone to sign in
create table if not exists shop_invites (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references shops on delete cascade,
  email text not null check (email = lower(email)),
  role shop_role not null default 'staff',
  invited_by uuid references auth.users on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  unique (shop_id, email)
);
alter table shop_invites enable row level security;
drop policy if exists "managers see invites" on shop_invites;
create policy "managers see invites" on shop_invites for select using (is_shop_manager(shop_id));
drop policy if exists "managers cancel invites" on shop_invites;
create policy "managers cancel invites" on shop_invites for delete using (is_shop_manager(shop_id));

-- the team list, with emails (only owners/managers can call it)
create or replace function shop_team(p_shop_id uuid)
returns table (user_id uuid, email text, role shop_role, is_you boolean)
language plpgsql stable security definer set search_path = public as $$
begin
  if not is_shop_manager(p_shop_id) then
    raise exception 'Only owners and managers can see the team.';
  end if;
  return query
    select sm.user_id, u.email::text, sm.role, sm.user_id = auth.uid()
    from shop_members sm join auth.users u on u.id = sm.user_id
    where sm.shop_id = p_shop_id
    order by sm.role, u.email; -- enums sort in the order we declared them: owner, manager, staff
end; $$;

create or replace function invite_member(p_shop_id uuid, p_email text, p_role shop_role default 'staff')
returns void language plpgsql security definer set search_path = public as $$
declare v_email text := lower(trim(p_email));
begin
  if not is_shop_manager(p_shop_id) then raise exception 'Only owners and managers can invite.'; end if;
  if p_role <> 'staff' and not is_shop_owner(p_shop_id) then
    raise exception 'Only owners can invite managers or owners.';
  end if;
  if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then raise exception 'That email doesn''t look right.'; end if;
  if exists (select 1 from shop_members sm join auth.users u on u.id = sm.user_id
             where sm.shop_id = p_shop_id and lower(u.email) = v_email) then
    raise exception 'They''re already on the team.';
  end if;

  -- inviting the same email again just updates the role
  insert into shop_invites (shop_id, email, role) values (p_shop_id, v_email, p_role)
  on conflict (shop_id, email) do update set role = excluded.role, created_at = now();
end; $$;

-- called right after sign in: turns any invites for your email into real memberships
create or replace function claim_invites()
returns int language plpgsql security definer set search_path = public as $$
declare v_email text; v_count int;
begin
  select lower(email) into v_email from auth.users where id = auth.uid();
  if v_email is null then return 0; end if;

  with moved as (
    delete from shop_invites where email = v_email returning shop_id, role
  )
  insert into shop_members (shop_id, user_id, role)
  select shop_id, auth.uid(), role from moved
  on conflict (shop_id, user_id) do nothing;

  get diagnostics v_count = row_count;
  return v_count;
end; $$;

create or replace function set_member_role(p_shop_id uuid, p_user_id uuid, p_role shop_role)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_shop_owner(p_shop_id) then raise exception 'Only owners can change roles.'; end if;
  if p_role <> 'owner'
     and (select role from shop_members where shop_id = p_shop_id and user_id = p_user_id) = 'owner'
     and (select count(*) from shop_members where shop_id = p_shop_id and role = 'owner') = 1 then
    raise exception 'A shop needs at least one owner.';
  end if;
  update shop_members set role = p_role where shop_id = p_shop_id and user_id = p_user_id;
end; $$;

create or replace function remove_member(p_shop_id uuid, p_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare v_target shop_role;
begin
  select role into v_target from shop_members where shop_id = p_shop_id and user_id = p_user_id;
  if v_target is null then raise exception 'They''re not on the team.'; end if;

  -- owners can remove anyone, managers only staff
  if not (is_shop_owner(p_shop_id) or (is_shop_manager(p_shop_id) and v_target = 'staff')) then
    raise exception 'You can''t remove them.';
  end if;
  if v_target = 'owner' and (select count(*) from shop_members where shop_id = p_shop_id and role = 'owner') = 1 then
    raise exception 'A shop needs at least one owner.';
  end if;

  delete from shop_members where shop_id = p_shop_id and user_id = p_user_id;
end; $$;

-- postgres lets everyone run new functions by default, lock these to signed in users
revoke execute on function shop_team(uuid), invite_member(uuid, text, shop_role), claim_invites(),
  set_member_role(uuid, uuid, shop_role), remove_member(uuid, uuid) from public, anon;
grant execute on function shop_team(uuid), invite_member(uuid, text, shop_role), claim_invites(),
  set_member_role(uuid, uuid, shop_role), remove_member(uuid, uuid) to authenticated;
