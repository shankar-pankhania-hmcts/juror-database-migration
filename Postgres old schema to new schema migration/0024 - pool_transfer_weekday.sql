/*
 * 
 * +---------------+---------------+-----------------------+---------------+-----------------------+
 * | Script Number | Source Schema |     Source Table      | Target Schema |     Target Table      |
 * +---------------+---------------+-----------------------+---------------+-----------------------+
 * |          0024 | juror         | pool_transfer_weekday | juror_mod     | pool_transfer_weekday |
 * +---------------+---------------+-----------------------+---------------+-----------------------+
 * 
 * pool_transfer_weekday
 * ---------------------
 */

delete from juror_mod.migration_log where script_number = '0024';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0024', 'juror', 'pool_transfer_weekday', 'juror_mod', 'pool_transfer_weekday', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.pool_transfer_weekday),
		expected_target_count = (select count(1) from juror.pool_transfer_weekday)
where 	script_number = '0024';

do $$

begin

truncate table juror_mod.pool_transfer_weekday;

with target as (
	insert into juror_mod.pool_transfer_weekday(transfer_day,run_day,adjustment)
	select distinct 
			ptw.transfer_day,
			ptw.run_day,
			ptw.adjustment
	from juror.pool_transfer_weekday ptw
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0024';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0024';
	
end $$;

-- verify results
select * from juror_mod.migration_log where script_number = '0024';
select * from juror_mod.pool_transfer_weekday limit 10;