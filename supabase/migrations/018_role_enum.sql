-- turn shop_members.role into a real enum so generated types know the 3 options

create type shop_role as enum ('owner', 'manager', 'staff');

-- the old check does the same job as the enum now, so drop it
alter table shop_members drop constraint shop_members_role_check;

-- convert the column in place, existing rows keep their values
alter table shop_members
  alter column role type shop_role using role::shop_role;
