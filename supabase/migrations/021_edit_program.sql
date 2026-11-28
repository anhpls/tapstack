-- owners and managers can change their shop's stamp card (staff can only look)
create policy "managers edit program" on stamp_programs for update
using (exists (
  select 1 from shop_members sm
  where sm.shop_id = stamp_programs.shop_id
    and sm.user_id = auth.uid()
    and sm.role in ('owner', 'manager')
))
with check (exists (
  select 1 from shop_members sm
  where sm.shop_id = stamp_programs.shop_id
    and sm.user_id = auth.uid()
    and sm.role in ('owner', 'manager')
));

-- sane limits, enforced by the db no matter who's writing
alter table stamp_programs
  add constraint stamps_needed_range check (stamps_needed between 1 and 50),
  add constraint max_per_visit_range check (max_stamps_per_visit between 1 and 20),
  add constraint reward_length check (length(trim(reward)) between 1 and 80);
