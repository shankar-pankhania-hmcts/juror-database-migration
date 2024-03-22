/*
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0004 | juror_digital | court_region | juror_mod     | court_region |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * court_region
 * ------------
 * 
 */


delete from juror_mod.migration_log where script_number = '0004';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0004', 'juror_digital', 'court_region', 'juror_mod', 'court_region');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.court_region),
		expected_target_count = (select count(1) from juror_digital.court_region)
where 	script_number = '0004';

do $$

begin

truncate table juror_mod.court_region;

with target
as
(
	insert into juror_mod.court_region(region_id,region_name,notify_account_key)
	select distinct 
			cr.region_id, 
			cr.region_name, 
			cr.notify_account_key
	from juror_digital.court_region cr
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(*) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0004';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0004';
end $$;

-- verify results
select * from juror_mod.migration_log where script_number = '0004';
select * from juror_mod.court_region limit 10;
