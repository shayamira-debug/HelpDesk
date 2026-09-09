-- HelpDesk V1.3.1 - Verify/enable Realtime publication

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

-- Recommended for richer UPDATE/DELETE realtime payloads.
alter table public.maintenance_tickets replica identity full;

-- Verification: should return exactly one row.
select pubname, schemaname, tablename
from pg_publication_tables
where pubname='supabase_realtime'
  and schemaname='public'
  and tablename='maintenance_tickets';