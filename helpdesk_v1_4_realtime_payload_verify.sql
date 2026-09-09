-- HelpDesk V1.4 - Realtime payload verification
-- Run only if you have not already run the V1.3.1 Realtime verification.

alter table public.maintenance_tickets replica identity full;

select pubname, schemaname, tablename
from pg_publication_tables
where pubname='supabase_realtime'
  and schemaname='public'
  and tablename='maintenance_tickets';