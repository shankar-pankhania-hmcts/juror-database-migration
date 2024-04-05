/*
 * 
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0032 | juror         | accused      | juror_mod     | accused      |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * accused
 * -------
 */

delete from juror_mod.migration_log where script_number = '0032';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0032', 'juror', 'accused', 'juror_mod', 'accused', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.accused),
		expected_target_count = (select count(1) from juror.accused)
where 	script_number = '0032';

do $$

begin

truncate table juror_mod.accused;

with target as (
	insert into juror_mod.accused("owner",trial_no,lname,fname)
	select distinct 
			a."owner",
			a.trial_no,
			a.lname,
			a.fname
	from juror.accused a
	returning 1
 )


update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0032';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0032';
	
end $$;
	
-- verify results
select * from juror_mod.migration_log where script_number = '0032';
select * from juror_mod.accused limit 10;