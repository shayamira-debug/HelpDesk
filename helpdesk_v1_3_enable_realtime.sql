-- HelpDesk V1.3 - Enable Realtime for maintenance_tickets
-- Run once in Supabase SQL Editor.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'maintenance_tickets'
  ) then
    alter publication supabase_realtime
    add table public.maintenance_tickets;
  end if;
end
$$;

-- Optional verification
select
  pubname,
  schemaname,
  tablename
from pg_publication_tables
where pubname = 'supabase_realtime'
  and schemaname = 'public'
  and tablename = 'maintenance_tickets';