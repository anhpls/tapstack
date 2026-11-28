-- owners and managers can edit their shop's details
drop policy if exists "managers edit shop" on shops;
create policy "managers edit shop" on shops for update
using (is_shop_manager(id))
with check (is_shop_manager(id));

-- rls picks the rows, this picks the columns: only these 3 are editable from the app
-- (keeps is_test locked so nobody can turn on self-stamping)
revoke update on shops from authenticated, anon;
grant update (name, category, color_hex) on shops to authenticated;

-- colors have to be real hex like #5B7DB1
alter table shops drop constraint if exists color_hex_format;
alter table shops add constraint color_hex_format check (color_hex ~ '^#[0-9A-Fa-f]{6}$');
alter table shops drop constraint if exists name_length;
alter table shops add constraint name_length check (length(trim(name)) between 1 and 60);
