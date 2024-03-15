/*
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0015 | juror         | unique_pool  | juror_mod     | pool         |
 * +---------------+---------------+--------------+---------------+--------------+
 *  
 * pool
 * ----
 */

delete from juror_mod.migration_log where script_number like '0015%';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0015a', 'juror', 'unique_pool', 'juror_mod', 'pool');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.unique_pool),
		expected_target_count = (select count(distinct pool_no) from juror.unique_pool)
where 	script_number = '0015a';

do $$

begin
	
alter table juror_mod.juror_pool
   drop constraint if exists juror_pool_pool_no_fk; 

alter table juror_mod.pool_comments
   drop constraint if exists pool_comments_pool_no_fk; 

alter table juror_mod.pool_comments 
	drop constraint if exists pool_comments_fk;

alter table juror_mod.appearance 
	drop constraint if exists appearance_pool_fk;

truncate table juror_mod.pool;

-- insert existing field data from juror schema
with target as (
    	insert into juror_mod.pool("owner",pool_no,return_date,no_requested,pool_type,loc_code,new_request,last_update,additional_summons,attend_time,total_no_required)
    	select distinct 
    			p."owner",
    			p.pool_no,
    			p.return_date,
    			p.no_requested,
    			p.pool_type,
    			p.loc_code,
    			p.new_request,
    			p.last_update,
    			p.additional_summons,
    			p.attend_time,
    			0 as total_no_required -- nulls not allowed  - default to 0
    	from juror.unique_pool p
    	where read_only = 'N'  -- editable so current record
    	returning 1
    )

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0015a';

alter table juror_mod.juror_pool
   add constraint juror_pool_pool_no_fk foreign key (pool_number) references juror_mod.pool(pool_no); 

alter table juror_mod.pool_comments
   add constraint pool_comments_pool_no_fk foreign key (pool_no) references juror_mod.pool(pool_no);

alter table juror_mod.appearance 
	add constraint appearance_pool_fk foreign key (pool_number) references juror_mod.pool(pool_no);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0015a';
	
end $$;


/*
 * 
 * In the Heritage JUROR schema - nil_pools were created as a record in the UNIQUE_POOL table and could only be identified as having 
 * number_requested = 0 and no associated pool members in the JUROR.POOL table (joining on pool_no)
 *
 * As part of migration we need to identify nil_pool in the old schema using number_requested = 0 and no associated pool members in 
 * the JUROR.POOL table (joining on pool_no) and set the nil_pool flag in the new schema/table to true, else set it to false.
 */

do $$

begin

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0015b', 'juror', 'unique_pool', 'juror_mod', 'pool (nil_pool)');


with nil_pools as (
	select 		p.pool_no
	from		juror_mod.pool p
	left join 	juror.pool jp 
	on 			jp.pool_no = p.pool_no 
				and jp.is_active = 'Y' 
				and jp.read_only = 'N'
	where 		p.no_requested = 0
				and jp.pool_no is null -- no active pool members	
)

update	juror_mod.migration_log
set		source_count = (select count(1) from nil_pools),
		expected_target_count = (select count(distinct pool_no) from nil_pools)
where 	script_number = '0015b';
    

update 		juror_mod.pool 
set 		nil_pool = true
from 		juror.unique_pool up
left join 	juror.pool jp 
on 			jp.pool_no = up.pool_no 
			and jp.is_active = 'Y' 
			and jp.read_only = 'N'
where 		up.no_requested = 0
			and jp.pool_no is null; -- no active pool members



update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from juror_mod.pool where nil_pool = true),
		"status" = 'COMPLETE'
where 	script_number = '0015b';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0015b';
	
end $$;

select * from juror_mod.migration_log where script_number like '0015%' order by script_number;
select * from juror_mod.pool limit 10;
