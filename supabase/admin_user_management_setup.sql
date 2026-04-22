alter table public.profiles
  add column if not exists email text,
  add column if not exists account_status text not null default 'active',
  add column if not exists admin_status_message text,
  add column if not exists admin_status_changed_at timestamptz,
  add column if not exists admin_status_changed_by uuid references auth.users (id) on delete set null;

create index if not exists idx_profiles_user_type on public.profiles(user_type);
create index if not exists idx_profiles_account_status on public.profiles(account_status);

update public.profiles as profiles
set email = users.email
from auth.users as users
where profiles.id = users.id
  and (
    profiles.email is null
    or btrim(profiles.email) = ''
  );

update public.profiles
set account_status = 'active'
where account_status is null
   or btrim(account_status) = '';

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    username,
    first_name,
    last_name,
    full_name,
    name,
    email,
    phone,
    location,
    user_type,
    account_status,
    language,
    theme,
    created_at,
    updated_at
  )
  values (
    new.id,
    new.raw_user_meta_data ->> 'username',
    new.raw_user_meta_data ->> 'first_name',
    new.raw_user_meta_data ->> 'last_name',
    new.raw_user_meta_data ->> 'full_name',
    new.raw_user_meta_data ->> 'name',
    new.email,
    new.raw_user_meta_data ->> 'phone',
    new.raw_user_meta_data ->> 'location',
    coalesce(new.raw_user_meta_data ->> 'user_type', 'farmer'),
    'active',
    coalesce(new.raw_user_meta_data ->> 'language', 'es'),
    coalesce(new.raw_user_meta_data ->> 'theme', 'system'),
    now(),
    now()
  )
  on conflict (id) do update set
    email = excluded.email,
    updated_at = now();

  return new;
end;
$$;

create or replace function public.is_admin(check_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = check_user_id
      and lower(coalesce(user_type, '')) = 'admin'
      and lower(coalesce(account_status, 'active')) = 'active'
  );
$$;

grant execute on function public.is_admin(uuid) to authenticated;

drop policy if exists "profiles_select_admin" on public.profiles;
create policy "profiles_select_admin"
on public.profiles
for select
to authenticated
using (public.is_admin());

drop policy if exists "profiles_update_admin" on public.profiles;
create policy "profiles_update_admin"
on public.profiles
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "animals_select_admin" on public.animals;
create policy "animals_select_admin"
on public.animals
for select
to authenticated
using (public.is_admin());

drop policy if exists "medical_records_select_admin" on public.medical_records;
create policy "medical_records_select_admin"
on public.medical_records
for select
to authenticated
using (public.is_admin());

drop policy if exists "notifications_select_admin" on public.notifications;
create policy "notifications_select_admin"
on public.notifications
for select
to authenticated
using (public.is_admin());

update public.profiles
set user_type = 'admin',
    updated_at = now()
where email = 'replace-with-admin-email@example.com';
