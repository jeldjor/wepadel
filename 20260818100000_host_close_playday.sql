-- Host-controlled playday closing.
-- The host is the only person who finalizes a playday. No participant review is required.

create or replace function public.close_playday(p_playday_id uuid)
returns public.playdays
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_playday public.playdays;
  v_host uuid;
  v_user uuid := (select auth.uid());
begin
  select p.host_id into v_host from public.playdays p where p.id = p_playday_id;
  if v_host is null then raise exception 'Speeldag niet gevonden'; end if;
  if v_host <> v_user then raise exception 'Alleen de host kan de speeldag afsluiten'; end if;

  update public.playdays
  set status = 'closed'::public.playday_status,
      session_status = 'approved'::public.session_status,
      approved_at = coalesce(approved_at, now())
  where id = p_playday_id
  returning * into v_playday;

  return v_playday;
end;
$$;

revoke all on function public.close_playday(uuid) from public, anon;
grant execute on function public.close_playday(uuid) to authenticated;

-- Participant reviews no longer control the playday status.
create or replace function public.evaluate_session_reviews()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  return new;
end;
$$;
