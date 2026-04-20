create table if not exists public.animal_diagnostics (
  id uuid primary key,
  animal_id uuid not null,
  user_id uuid not null,
  animal_name text not null,
  primary_diagnosis text,
  diagnostic_statement text,
  report_url text not null,
  image_url text,
  created_at timestamptz not null default now()
);

create index if not exists animal_diagnostics_animal_id_idx
  on public.animal_diagnostics (animal_id);

create index if not exists animal_diagnostics_user_id_idx
  on public.animal_diagnostics (user_id);

alter table public.animal_diagnostics enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'animal_diagnostics'
      and policyname = 'animal_diagnostics_select_own'
  ) then
    create policy animal_diagnostics_select_own
      on public.animal_diagnostics
      for select
      to authenticated
      using (auth.uid() = user_id);
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'animal_diagnostics'
      and policyname = 'animal_diagnostics_insert_own'
  ) then
    create policy animal_diagnostics_insert_own
      on public.animal_diagnostics
      for insert
      to authenticated
      with check (auth.uid() = user_id);
  end if;
end $$;
