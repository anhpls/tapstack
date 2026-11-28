-- one row per customer for the dashboard's customers table
create or replace function shop_customers(p_shop_id uuid)
returns table (
  membership_id uuid,
  member_number text,
  joined_at timestamptz,
  from_paper boolean,
  visits int,
  last_visit timestamptz,
  balance int,
  rewards int
)
language sql
stable
security invoker  -- staff read rules still apply
set search_path = public
as $$
  select
    m.id,
    m.member_number,
    m.created_at,
    -- did they move a paper card over?
    exists (select 1 from transfer_requests t
            where t.shop_id = m.shop_id and t.user_id = m.user_id and t.status = 'completed'),
    -- same visit counting as shop_activity
    (select count(distinct coalesce(s.visit_id, s.id))::int from stamps s
      where s.membership_id = m.id and s.reason = 'purchase'),
    (select max(s.created_at) from stamps s
      where s.membership_id = m.id and s.reason = 'purchase'),
    balance(m),
    (select count(*)::int from redemptions r where r.membership_id = m.id)
  from memberships m
  where m.shop_id = p_shop_id
    and m.hidden_at is null
  order by 6 desc nulls last; -- most recent visit first
$$;
