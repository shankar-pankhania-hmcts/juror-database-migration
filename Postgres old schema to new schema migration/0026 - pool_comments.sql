/*
 * 
 * +---------------+---------------+---------------+---------------+---------------+
 * | Script Number | Source Schema | Source Table  | Target Schema | Target Table  |
 * +---------------+---------------+---------------+---------------+---------------+
 * |          0026 | juror         | pool_comments | juror_mod     | pool_comments |
 * +---------------+---------------+---------------+---------------+---------------+
 * 
 * pool_comments
 * -------------
 */

delete from juror_mod.migration_log where script_number = '0026';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0026', 'juror', 'pool_comments', 'juror_mod', 'pool_comments', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.pool_comments),
		expected_target_count = (select count(1) from (
			select distinct 
					pc.pool_no,
					pc.user_id,
					pc.last_update,
					pc.pcomment,
					pc.no_requested
			from juror.pool_comments))
where 	script_number = '0026';

do $$

begin

alter table juror_mod.pool_comments 
	drop constraint pool_comments_fk;

alter table juror_mod.pool_comments 
	drop constraint pool_comments_pool_no_fk;

truncate juror_mod.pool_comments restart identity cascade;

with target as (
 	insert into juror_mod.pool_comments(pool_no,user_id,last_update,pcomment,no_requested)
	select distinct 
			pc.pool_no,
			pc.user_id,
			pc.last_update,
			pc.pcomment,
			pc.no_requested
	from juror.pool_comments pc
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0026';


alter table juror_mod.pool_comments 
	add constraint pool_comments_pool_no_fk foreign key (pool_no) references juror_mod.pool(pool_no);


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0026';
	
end $$;

-- verify results
select * from juror_mod.migration_log where script_number = '0026';
select * from juror_mod.pool_comments limit 10;