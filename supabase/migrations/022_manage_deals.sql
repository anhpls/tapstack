-- reusable check: am i an owner or manager at this shop?
create or replace function is_shop_manager(p_shop_id uuid)
returns boolean
language sql stable security invoker
set search_path = public
as $$
  select exists (
    select 1 from shop_members
    where shop_id = p_shop_id and user_id = auth.uid() and role in ('owner', 'manager')
  );
$$;

create policy "managers add deals"    on stamp_promos for insert with check (is_shop_manager(shop_id));
create policy "managers edit deals"   on stamp_promos for update using (is_shop_manager(shop_id)) with check (is_shop_manager(shop_id));
create policy "managers remove deals" on stamp_promos for delete using (is_shop_manager(shop_id));
