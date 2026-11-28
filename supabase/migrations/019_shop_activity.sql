-- how many customers came in lately, and how many came back more than once
create or replace function shop_activity(p_shop_id uuid, p_days int default 30)
returns table (active_count int, repeat_count int)
language sql
stable            -- only reads, never writes
security invoker  -- runs as you, so the normal staff read rules still apply
set search_path = public
as $$
  with visits as (
    select s.membership_id,
           -- one visit = one stamping session; old stamps without a visit_id count on their own
           count(distinct coalesce(s.visit_id, s.id)) as n
    from stamps s
    join memberships m on m.id = s.membership_id
    where m.shop_id = p_shop_id
      and s.reason = 'purchase'
      and s.created_at > now() - make_interval(days => p_days)
    group by s.membership_id
  )
  select count(*)::int,
         (count(*) filter (where n >= 2))::int
  from visits;
$$;
