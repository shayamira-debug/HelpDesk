-- HelpDesk V1.6
-- 1) הרשאות: מנהל רואה הכל; מטפל רואה ומעדכן רק קריאות המשויכות אליו.
-- 2) ניקוי כל הקריאות וההיסטוריה והתחלה מחדש ממספר קריאה 1.
-- משתמשים אינם נמחקים.

-- --- A. Rebuild SELECT / UPDATE policies on maintenance_tickets ---
do $$
declare
  p record;
begin
  for p in
    select policyname
    from pg_policies
    where schemaname='public'
      and tablename='maintenance_tickets'
      and cmd in ('SELECT','UPDATE')
  loop
    execute format('drop policy if exists %I on public.maintenance_tickets', p.policyname);
  end loop;
end
$$;

create policy "tickets_select_by_role"
on public.maintenance_tickets
for select
to authenticated
using (
  requester_user_id = auth.uid()
  or public.is_maintenance_manager()
  or exists (
    select 1
    from public.maintenance_users mu
    where mu.auth_user_id = auth.uid()
      and mu.is_active = true
      and mu.role = 'technician'
      and maintenance_tickets.assigned_to = mu.id
  )
);

create policy "tickets_update_by_role"
on public.maintenance_tickets
for update
to authenticated
using (
  public.is_maintenance_manager()
  or exists (
    select 1
    from public.maintenance_users mu
    where mu.auth_user_id = auth.uid()
      and mu.is_active = true
      and mu.role = 'technician'
      and maintenance_tickets.assigned_to = mu.id
  )
)
with check (
  public.is_maintenance_manager()
  or exists (
    select 1
    from public.maintenance_users mu
    where mu.auth_user_id = auth.uid()
      and mu.is_active = true
      and mu.role = 'technician'
      and maintenance_tickets.assigned_to = mu.id
  )
);

-- --- B. History visibility should follow ticket visibility ---
do $$
declare
  p record;
begin
  for p in
    select policyname
    from pg_policies
    where schemaname='public'
      and tablename='maintenance_ticket_history'
      and cmd='SELECT'
  loop
    execute format('drop policy if exists %I on public.maintenance_ticket_history', p.policyname);
  end loop;
end
$$;

create policy "history_select_by_ticket_access"
on public.maintenance_ticket_history
for select
to authenticated
using (
  exists (
    select 1
    from public.maintenance_tickets t
    where t.id = maintenance_ticket_history.ticket_id
  )
);

-- --- C. Clear tickets/history and restart ticket number from 1 ---
truncate table
  public.maintenance_ticket_history,
  public.maintenance_tickets
restart identity cascade;

-- Verification
select count(*) as tickets_after_cleanup from public.maintenance_tickets;
select count(*) as history_after_cleanup from public.maintenance_ticket_history;