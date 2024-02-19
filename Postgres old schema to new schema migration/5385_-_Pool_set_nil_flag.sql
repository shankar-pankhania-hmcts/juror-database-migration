/*
 * 
 * In the Heritage JUROR schema - nil_pools were created as a record in the UNIQUE_POOL table and could only be identified as having 
 * number_requested = 0 and no associated pool members in the JUROR.POOL table (joining on pool_no)
 *
 * As part of migration we need to identify nil_pool in the old schema using number_requested = 0 and no associated pool members in 
 * the JUROR.POOL table (joining on pool_no) and set the nil_pool flag in the new schema/table to true, else set it to false.
 */


with rows
as
(
	update juror_mod.pool 
	set nil_pool = true
	from juror.unique_pool up
	left join juror.pool jp 
	on jp.pool_no = up.pool_no 
	and jp.is_active = 'Y' 
	and jp.read_only = 'N'
	where juror_mod.pool.pool_no = up.pool_no
	and up.no_requested = 0
	and jp.pool_no is null -- no active pools			
)
select count(*) from rows;  -- rows updated

-- check results
select count(*)
from juror.unique_pool up
left join juror.pool jp 
on jp.pool_no = up.pool_no 
and jp.is_active = 'Y' 
and jp.read_only = 'N'
where up.no_requested = 0
and jp.pool_no is null; -- no active pools

with rows
as
(
	update juror_mod.pool
	set nil_pool = true
	from (
			select up.pool_no 
			from juror.unique_pool up
			where up.no_requested = 0 
			group by up.pool_no 
			having count(up.pool_no) > 1
	     ) up
	where juror_mod.pool.pool_no = up.pool_no
)
select count(*) from rows;  -- rows updated

-- check results
select count(1) 
from juror.unique_pool up
where up.no_requested = 0 
group by up.pool_no 
having count(up.pool_no) > 1

-- verify results
select p.nil_pool, count(*) from juror_mod.pool p group by p.nil_pool;
