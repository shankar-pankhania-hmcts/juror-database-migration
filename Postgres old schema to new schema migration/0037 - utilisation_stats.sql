/*
 *
 * +---------------+---------------+--------------+---------------+-------------------+
 * | Script Number | Source Schema | Source Table | Target Schema |   Target Table    |
 * +---------------+---------------+--------------+---------------+-------------------+
 * |          0037 | juror         | attendance   | juror_mod     | utilisation_stats |
 * +---------------+---------------+--------------+---------------+-------------------+
 * 
 * utilisation_stats
 * -----------------
 */

delete from juror_mod.migration_log where script_number = '0037';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0037', 'juror', 'attendance', 'juror_mod', 'utilisation_stats', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror.attendance),
		expected_target_count = (select count(1) from juror.attendance)
where 	script_number = '0037';

do $$

begin

alter table juror_mod.utilisation_stats
	drop constraint if exists utilisation_stats_fk;

   
truncate table juror_mod.utilisation_stats;

with target as (
	insert into juror_mod.utilisation_stats(month_start,loc_code,available_days,attendance_days,sitting_days,no_trials,last_update)
	select distinct 
			a.month_start::date,
			a.loc_code,
			a.available_days,
			a.attendance_days,
			a.sitting_days,
			a.no_trials,
			a.last_update
	from juror.attendance a
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0037';

alter table juror_mod.utilisation_stats add constraint utilisation_stats_fk 
	foreign key (loc_code) references juror_mod.court_location(loc_code);


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0037';

end $$;


-- verify results
select * from juror_mod.migration_log where script_number = '0037';
select * from juror_mod.utilisation_stats limit 10;