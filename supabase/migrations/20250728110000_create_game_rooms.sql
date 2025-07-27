-- Migration to create game_rooms table with optional password and RLS policies

-- 1. Create table
create table if not exists public.game_rooms (
  id uuid not null default gen_random_uuid(),
  host_id uuid not null references auth.users(id) on delete cascade,
  room_name text not null unique,
  password text,
  created_at timestamp with time zone not null default current_timestamp,
  updated_at timestamp with time zone not null default current_timestamp,
  primary key (id)
);

-- 2. Function to update updated_at on change
create or replace function public.set_game_rooms_updated_at()
returns trigger as $$
begin
  new.updated_at = current_timestamp;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_set_game_rooms_updated_at on public.game_rooms;
create trigger trg_set_game_rooms_updated_at
before update on public.game_rooms
for each row
execute procedure public.set_game_rooms_updated_at();

-- 3. Enable Row Level Security
alter table public.game_rooms enable row level security;

-- 4. Policies
-- Allow all users to view game rooms
create policy "Users can view game rooms"
  on public.game_rooms
  for select
  using (true);

-- Allow authenticated users to create game rooms where they are the host
create policy "Users can create a game room"
  on public.game_rooms
  for insert to authenticated
  with check (auth.uid() = host_id);

-- Allow hosts to update their own game rooms
create policy "Users can update their own game room"
  on public.game_rooms
  for update to authenticated
  using (auth.uid() = host_id)
  with check (auth.uid() = host_id);

-- Allow hosts to delete their own game rooms
create policy "Users can delete their own game room"
  on public.game_rooms
  for delete to authenticated
  using (auth.uid() = host_id);
