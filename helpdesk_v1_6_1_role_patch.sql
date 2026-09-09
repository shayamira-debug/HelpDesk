-- HelpDesk V1.6.1
-- Add role 'chamber' while keeping:
-- employee = דייר
-- chamber = לשכה
-- technician = מטפל
-- manager = מנהל

-- Drop the current role CHECK constraint if one exists.
do $$
declare
  c record;
begin
  for c in
    select conname
    from pg_constraint
    where conrelid = 'public.maintenance_users'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%role%'
  loop
    execute format('alter table public.maintenance_users drop constraint if exists %I', c.conname);
  end loop;
end
$$;

alter table public.maintenance_users
add constraint maintenance_users_role_check
check (role in ('employee','chamber','technician','manager'));

-- Verification
select role, count(*)
from public.maintenance_users
group by role
order by role;