alter table public.notifications
add column if not exists local_notification_ids integer[] not null default '{}',
add column if not exists repeat_weekdays integer[] not null default '{}',
add column if not exists completed_at timestamptz,
add column if not exists deleted_at timestamptz;
