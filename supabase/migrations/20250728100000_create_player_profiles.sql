-- Migration to create player_profiles table and policies

-- 1. Create table
create table if not exists public.player_profiles (
  user_id uuid not null references auth.users (id) on delete cascade,
  username text not null unique,
  created_at timestamp with time zone not null default current_timestamp,
  updated_at timestamp with time zone not null default current_timestamp,
  primary key (user_id)
);

-- 2. Function to update updated_at on change
create or replace function public.set_player_profiles_updated_at()
returns trigger as $$
begin
  new.updated_at = current_timestamp;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_set_player_profiles_updated_at on public.player_profiles;
create trigger trg_set_player_profiles_updated_at
before update on public.player_profiles
for each row
execute procedure public.set_player_profiles_updated_at();

-- 3. Enable Row Level Security
alter table public.player_profiles enable row level security;

-- 4. Policies
create policy "Users can view their own player profile"
  on public.player_profiles
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can create their own player profile"
  on public.player_profiles
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update their own player profile"
  on public.player_profiles
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own player profile"
  on public.player_profiles
  for delete
  to authenticated
  using (auth.uid() = user_id);

-- 5. (Optional) Index to accelerate lookups by user_id (implicit via primary key)
-- create index if not exists idx_player_profiles_user_id on public.player_profiles(user_id);
