-- Supabase RPC Function: get_streak_summary
-- 
-- This function calculates reading streak statistics for the authenticated user.
-- It returns:
--   - today_read: Boolean indicating if user read today
--   - current_streak: Consecutive days from today backwards
--   - best_streak: Longest consecutive streak in history
--   - calendar: Array of last N days with read status
--
-- Usage in Flutter:
--   final result = await supabase.rpc('get_streak_summary', params: {'p_days': 30});
--
-- IMPORTANT: Run this SQL in Supabase SQL Editor manually.

create or replace function public.get_streak_summary(p_days int default 30)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := (now() at time zone 'Asia/Jakarta')::date;
  v_start date := v_today - (p_days - 1);
  v_today_read boolean;
  v_current_streak int := 0;
  v_best_streak int := 0;
  v_calendar jsonb := '[]'::jsonb;
  v_date date;
  v_has_read boolean;
begin
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- Distinct hari yang ada bacaan (semua waktu)
  -- Ini dipakai untuk current_streak & best_streak
  with user_days as (
    select distinct reading_date
    from public.reading_sessions
    where user_id = v_user_id
  )
  select exists (
    select 1 from user_days where reading_date = v_today
  )
  into v_today_read;

  -- Hitung current streak (mundur dari hari ini)
  if v_today_read then
    v_current_streak := 1;
    v_date := v_today - 1;

    while exists (
      select 1 from public.reading_sessions
      where user_id = v_user_id
        and reading_date = v_date
    )
    loop
      v_current_streak := v_current_streak + 1;
      v_date := v_date - 1;
    end loop;
  else
    v_current_streak := 0;
  end if;

  -- Hitung best streak sepanjang waktu
  -- Cara: ambil semua hari baca terurut, looping hitung streak terpanjang
  declare
    r record;
    v_last_date date := null;
    v_run int := 0;
  begin
    for r in
      select reading_date
      from (
        select distinct reading_date
        from public.reading_sessions
        where user_id = v_user_id
      ) d
      order by reading_date
    loop
      if v_last_date is null or r.reading_date = v_last_date + 1 then
        v_run := v_run + 1;
      else
        if v_run > v_best_streak then
          v_best_streak := v_run;
        end if;
        v_run := 1;
      end if;
      v_last_date := r.reading_date;
    end loop;

    if v_run > v_best_streak then
      v_best_streak := v_run;
    end if;
  end;

  -- Calendar N hari terakhir
  v_date := v_start;
  while v_date <= v_today loop
    select exists (
      select 1 from public.reading_sessions
      where user_id = v_user_id
        and reading_date = v_date
    )
    into v_has_read;

    v_calendar := v_calendar || jsonb_build_object(
      'date', to_char(v_date, 'YYYY-MM-DD'),
      'read', v_has_read
    );

    v_date := v_date + 1;
  end loop;

  return json_build_object(
    'today_read', v_today_read,
    'current_streak', v_current_streak,
    'best_streak', v_best_streak,
    'calendar', v_calendar
  );
end;
$$;

