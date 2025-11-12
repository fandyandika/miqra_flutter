-- ============================================
-- Miqra App Database Schema
-- Migration: Initial Schema
-- Created: 2025-01-11
-- ============================================

-- 1. Profiles
create table if not exists profiles (
  id uuid primary key references auth.users on delete cascade,
  email text unique not null,
  full_name text,
  avatar_url text,
  daily_goal int default 5 check (daily_goal between 1 and 100),
  timezone text default 'Asia/Jakarta',
  lat double precision check (lat between -90 and 90),
  lng double precision check (lng between -180 and 180),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 2. Streaks
create table if not exists streaks (
  user_id uuid primary key references profiles(id) on delete cascade,
  current_streak int default 0 check (current_streak >= 0),
  longest_streak int default 0 check (longest_streak >= 0),
  last_read_date date,
  streak_start_date date,
  updated_at timestamptz default now(),
  constraint longest_gte_current check (longest_streak >= current_streak)
);

-- 3. User Settings
create table if not exists user_settings (
  user_id uuid primary key references profiles(id) on delete cascade,
  hasanat_visible boolean default true,
  share_with_group boolean default false,
  join_leaderboard boolean default false,
  notification_enabled boolean default true,
  notification_time time default '20:00',
  streak_warning_enabled boolean default true,
  group_nudge_enabled boolean default false,
  milestone_celebration_enabled boolean default true,
  translation_visible boolean default true,
  tajweed_enabled boolean default true,
  font_size int default 24 check (font_size between 16 and 40),
  theme text default 'light' check (theme in ('light', 'dark')),
  last_read_surah int check (last_read_surah between 1 and 114),
  last_read_ayah int check (last_read_ayah >= 1),
  last_read_juz int check (last_read_juz between 1 and 30),
  last_read_page int check (last_read_page between 1 and 604),
  last_read_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 4. Checkins
create table if not exists checkins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  date date not null,
  ayah_count int default 0 check (ayah_count >= 0),
  hasanat_earned int default 0 check (hasanat_earned >= 0),
  created_at timestamptz default now(),
  unique(user_id, date)
);

-- ============================================
-- Row Level Security (RLS)
-- ============================================

alter table profiles enable row level security;
alter table streaks enable row level security;
alter table user_settings enable row level security;
alter table checkins enable row level security;

-- RLS Policies
create policy "Own profile only" on profiles 
  for all using (auth.uid() = id);

create policy "Own streak only" on streaks 
  for all using (auth.uid() = user_id);

create policy "Own settings only" on user_settings 
  for all using (auth.uid() = user_id);

create policy "Own checkins only" on checkins 
  for all using (auth.uid() = user_id);

-- ============================================
-- Indexes
-- ============================================

create index if not exists idx_checkins_user_date on checkins(user_id, date desc);
create index if not exists idx_streaks_user on streaks(user_id);

-- ============================================
-- Triggers
-- ============================================

-- Function to update updated_at timestamp
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Triggers
create trigger profiles_updated_at 
  before update on profiles 
  for each row execute function update_updated_at();

create trigger settings_updated_at 
  before update on user_settings 
  for each row execute function update_updated_at();

create trigger streaks_updated_at 
  before update on streaks 
  for each row execute function update_updated_at();

