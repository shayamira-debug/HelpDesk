-- HelpDesk V1.6.3 - role verification
-- Confirms that 'chamber' is a valid persisted role.

select conname, pg_get_constraintdef(oid)
from pg_constraint
where conrelid='public.maintenance_users'::regclass
  and contype='c';

-- Optional verification of current users:
select id, full_name, email, role, is_active
from public.maintenance_users
order by created_at desc;