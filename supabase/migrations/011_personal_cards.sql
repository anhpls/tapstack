-- cards for shops that aren't on Tapstack yet
create table personal_cards (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users on delete cascade not null default auth.uid(),
  shop_name text not null,
  category text not null check (category in ('cafe', 'boba', 'restaurant', 'bakery')),
  stamps_needed int not null check (stamps_needed between 1 and 30),
  pending_stamps int not null default 0 check (pending_stamps >= 0),  -- from the paper card, NOT verified
  image_path text,
  created_at timestamptz default now()
);
alter table personal_cards enable row level security;
create policy "own personal cards" on personal_cards for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- private image storage: each person gets a folder named after their user ID
insert into storage.buckets (id, name, public) values ('card-images', 'card-images', false);

create policy "upload own card images" on storage.objects for insert to authenticated
  with check (bucket_id = 'card-images' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "read own card images" on storage.objects for select to authenticated
  using (bucket_id = 'card-images' and (storage.foldername(name))[1] = auth.uid()::text);
