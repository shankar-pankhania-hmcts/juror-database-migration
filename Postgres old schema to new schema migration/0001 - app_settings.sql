/*
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0001 | juror_digital | app_settings | juror_mod     | app_settings |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * app_settings
 * ------------
 * 
 */

delete from juror_mod.migration_log where script_number = '0001';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0001', 'juror_digital', 'app_settings', 'juror_mod', 'app_settings');


with "source" as (
	select 	count(a.setting) as source_count,
			count(distinct a.setting) as expected_target_count
	from juror_digital.app_settings a
)

update	juror_mod.migration_log
set		source_count = (select source_count from "source"),
		expected_target_count = (select expected_target_count from "source")
where 	script_number = '0001';

do $$

begin

truncate table juror_mod.app_settings;

with target as (
	insert into juror_mod.app_settings(setting, "value")
	select distinct 
			a.setting,
			a.value
	from juror_digital.app_settings a
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(*) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0001';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0001';
end $$;

-- verify results
select * from juror_mod.migration_log;
select * from juror_mod.app_settings limit 10;