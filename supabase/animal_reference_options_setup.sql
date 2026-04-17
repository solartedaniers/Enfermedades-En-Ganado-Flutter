create table if not exists public.animal_reference_options (
  id bigserial primary key,
  category text not null check (category in ('breed', 'age')),
  value text not null,
  label_es text not null,
  label_en text not null,
  numeric_value integer,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now())
);

create unique index if not exists animal_reference_options_category_value_idx
  on public.animal_reference_options (category, value);

alter table public.animal_reference_options enable row level security;

drop policy if exists "Animal reference options are readable by authenticated users"
  on public.animal_reference_options;

create policy "Animal reference options are readable by authenticated users"
  on public.animal_reference_options
  for select
  to authenticated
  using (true);

insert into public.animal_reference_options (
  category,
  value,
  label_es,
  label_en,
  numeric_value,
  sort_order
)
values
  ('breed', 'aberdeen_angus', 'Aberdeen Angus', 'Aberdeen Angus', null, 10),
  ('breed', 'beefmaster', 'Beefmaster', 'Beefmaster', null, 20),
  ('breed', 'belgian_blue', 'Belgian Blue', 'Belgian Blue', null, 30),
  ('breed', 'blonde_d_aquitaine', 'Blonde d''Aquitaine', 'Blonde d''Aquitaine', null, 40),
  ('breed', 'bonsmara', 'Bonsmara', 'Bonsmara', null, 50),
  ('breed', 'brahman', 'Brahman', 'Brahman', null, 60),
  ('breed', 'brangus', 'Brangus', 'Brangus', null, 70),
  ('breed', 'brown_swiss', 'Brown Swiss', 'Brown Swiss', null, 80),
  ('breed', 'charolais', 'Charolais', 'Charolais', null, 90),
  ('breed', 'chianina', 'Chianina', 'Chianina', null, 100),
  ('breed', 'criollo', 'Criollo', 'Criollo', null, 110),
  ('breed', 'devon', 'Devon', 'Devon', null, 120),
  ('breed', 'droughtmaster', 'Droughtmaster', 'Droughtmaster', null, 130),
  ('breed', 'fleckvieh', 'Fleckvieh', 'Fleckvieh', null, 140),
  ('breed', 'gelbvieh', 'Gelbvieh', 'Gelbvieh', null, 150),
  ('breed', 'gir', 'Gir', 'Gir', null, 160),
  ('breed', 'guzera', 'Guzera', 'Guzera', null, 170),
  ('breed', 'hereford', 'Hereford', 'Hereford', null, 180),
  ('breed', 'holstein_friesian', 'Holstein Friesian', 'Holstein Friesian', null, 190),
  ('breed', 'jersey', 'Jersey', 'Jersey', null, 200),
  ('breed', 'limousin', 'Limousin', 'Limousin', null, 210),
  ('breed', 'longhorn', 'Longhorn', 'Longhorn', null, 220),
  ('breed', 'maine_anjou', 'Maine-Anjou', 'Maine-Anjou', null, 230),
  ('breed', 'marchigiana', 'Marchigiana', 'Marchigiana', null, 240),
  ('breed', 'montbeliarde', 'Montbeliarde', 'Montbeliarde', null, 250),
  ('breed', 'murray_grey', 'Murray Grey', 'Murray Grey', null, 260),
  ('breed', 'nelore', 'Nelore', 'Nelore', null, 270),
  ('breed', 'normande', 'Normande', 'Normande', null, 280),
  ('breed', 'piedmontese', 'Piedmontese', 'Piedmontese', null, 290),
  ('breed', 'pinzgauer', 'Pinzgauer', 'Pinzgauer', null, 300),
  ('breed', 'red_angus', 'Red Angus', 'Red Angus', null, 310),
  ('breed', 'red_poll', 'Red Poll', 'Red Poll', null, 320),
  ('breed', 'romosinuano', 'Romosinuano', 'Romosinuano', null, 330),
  ('breed', 'sahiwal', 'Sahiwal', 'Sahiwal', null, 340),
  ('breed', 'salorn', 'Salorn', 'Salorn', null, 350),
  ('breed', 'santa_gertrudis', 'Santa Gertrudis', 'Santa Gertrudis', null, 360),
  ('breed', 'senepol', 'Senepol', 'Senepol', null, 370),
  ('breed', 'shorthorn', 'Shorthorn', 'Shorthorn', null, 380),
  ('breed', 'simmental', 'Simmental', 'Simmental', null, 390),
  ('breed', 'taurus', 'Taurus', 'Taurus', null, 400),
  ('breed', 'zebu_cebu', 'Cebu', 'Zebu (Cebu)', null, 410),
  ('age', '1_month', '1 mes', '1 month', 1, 10),
  ('age', '2_months', '2 meses', '2 months', 2, 20),
  ('age', '3_months', '3 meses', '3 months', 3, 30),
  ('age', '4_months', '4 meses', '4 months', 4, 40),
  ('age', '5_months', '5 meses', '5 months', 5, 50),
  ('age', '6_months', '6 meses', '6 months', 6, 60),
  ('age', '7_months', '7 meses', '7 months', 7, 70),
  ('age', '8_months', '8 meses', '8 months', 8, 80),
  ('age', '9_months', '9 meses', '9 months', 9, 90),
  ('age', '10_months', '10 meses', '10 months', 10, 100),
  ('age', '11_months', '11 meses', '11 months', 11, 110),
  ('age', '1_year', '1 ano', '1 year', 12, 120),
  ('age', '2_years', '2 anos', '2 years', 24, 130),
  ('age', '3_years', '3 anos', '3 years', 36, 140),
  ('age', '4_years', '4 anos', '4 years', 48, 150),
  ('age', '5_years', '5 anos', '5 years', 60, 160),
  ('age', '6_years', '6 anos', '6 years', 72, 170),
  ('age', '7_years', '7 anos', '7 years', 84, 180),
  ('age', '8_years', '8 anos', '8 years', 96, 190),
  ('age', '9_years', '9 anos', '9 years', 108, 200),
  ('age', '10_years', '10 anos', '10 years', 120, 210),
  ('age', '11_years', '11 anos', '11 years', 132, 220),
  ('age', '12_years', '12 anos', '12 years', 144, 230),
  ('age', '13_years', '13 anos', '13 years', 156, 240),
  ('age', '14_years', '14 anos', '14 years', 168, 250),
  ('age', '15_years', '15 anos', '15 years', 180, 260),
  ('age', '16_years', '16 anos', '16 years', 192, 270),
  ('age', '17_years', '17 anos', '17 years', 204, 280),
  ('age', '18_years', '18 anos', '18 years', 216, 290),
  ('age', '19_years', '19 anos', '19 years', 228, 300),
  ('age', '20_years', '20 anos', '20 years', 240, 310),
  ('age', '21_years', '21 anos', '21 years', 252, 320),
  ('age', '22_years', '22 anos', '22 years', 264, 330),
  ('age', '23_years', '23 anos', '23 years', 276, 340),
  ('age', '24_years', '24 anos', '24 years', 288, 350),
  ('age', '25_years', '25 anos', '25 years', 300, 360)
on conflict (category, value) do update set
  label_es = excluded.label_es,
  label_en = excluded.label_en,
  numeric_value = excluded.numeric_value,
  sort_order = excluded.sort_order,
  is_active = true;
