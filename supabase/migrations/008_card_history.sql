-- one row per event: a visit, a reward, or a correction
create or replace function card_history(p_membership_id uuid)
returns table (happened_at timestamptz, kind text, change int, bonus int, note text)
language sql stable
as $$
  -- stamps, grouped so one visit = one row (stamps from one action share a timestamp)
  select min(s.created_at),
         case when bool_or(s.reason = 'correction') then 'correction' else 'visit' end,
         sum(s.amount)::int,
         sum(case when s.reason = 'promo' then s.amount else 0 end)::int,
         null::text
  from stamps s
  where s.membership_id = p_membership_id
  group by coalesce(s.visit_id::text, s.created_at::text)

  union all

  -- rewards redeemed
  select r.created_at, 'reward', -r.stamps_used, 0, r.reward
  from redemptions r
  where r.membership_id = p_membership_id

  order by 1 desc
  limit 30
$$;
