-- a counter that only goes up: 1000001, 1000002, ...
create sequence member_number_seq start 1000001;

-- the app's signed-in users need permission to use the counter
grant usage on sequence member_number_seq to authenticated;

-- every new membership gets the next number, like TS-1000001
alter table memberships
  alter column member_number
  set default 'TS-' || nextval('member_number_seq')::text;
