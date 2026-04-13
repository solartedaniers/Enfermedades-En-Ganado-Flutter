create table if not exists public.managed_clients (
  id uuid primary key,
  veterinarian_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  location text not null default '',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.managed_client_animals (
  veterinarian_id uuid not null references auth.users (id) on delete cascade,
  animal_id uuid not null,
  client_id uuid not null references public.managed_clients (id) on delete cascade,
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (veterinarian_id, animal_id)
);

alter table public.managed_clients enable row level security;
alter table public.managed_client_animals enable row level security;

create policy if not exists "Managed clients owner access"
on public.managed_clients
for all
using (auth.uid() = veterinarian_id)
with check (auth.uid() = veterinarian_id);

create policy if not exists "Managed client animal links owner access"
on public.managed_client_animals
for all
using (auth.uid() = veterinarian_id)
with check (auth.uid() = veterinarian_id);
