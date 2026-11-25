create or replace function card_history(p_membership_id uuid)
returns table (happened_at timestamptz, kind text, change int, bonus int, note text)
language sql stable
as $$
  -- visits (everything except corrections), one row per visit
  select min(s.created_at), 'visit',
         sum(s.amount)::int,
         sum(case when s.reason = 'promo' then s.amount else 0 end)::int,
         null::text
  from stamps s
  where s.membership_id = p_membership_id and s.reason <> 'correction'
  group by coalesce(s.visit_id::text, s.created_at::text)

  union all

  -- corrections: combined per day, and hidden if they cancel out
  select max(s.created_at), 'adjustment', sum(s.amount)::int, 0, null::text
  from stamps s
  where s.membership_id = p_membership_id and s.reason = 'correction'
  group by date_trunc('day', s.created_at)
  having sum(s.amount) <> 0

  union all

  -- rewards redeemed
  select r.created_at, 'reward', -r.stamps_used, 0, r.reward
  from redemptions r
  where r.membership_id = p_membership_id

  order by 1 desc
  limit 30
$$;
