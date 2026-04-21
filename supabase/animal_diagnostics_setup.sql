create table if not exists public.animal_diagnostics (
  id uuid primary key,
  animal_id uuid not null,
  diagnosis_summary text not null,
  report_url text not null,
  created_at timestamptz not null default now()
);

create index if not exists animal_diagnostics_animal_id_idx
  on public.animal_diagnostics (animal_id);
