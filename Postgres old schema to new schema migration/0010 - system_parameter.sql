/*
 * +---------------+---------------+------------------+---------------+------------------+
 * | Script Number | Source Schema |   Source Table   | Target Schema |   Target Table   |
 * +---------------+---------------+------------------+---------------+------------------+
 * |          0010 | juror         | system_parameter | juror_mod     | system_parameter |
 * +---------------+---------------+------------------+---------------+------------------+
 *
 * system_parameter
 * ----------------
 *
*/

delete from juror_mod.migration_log where script_number = '0010';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0010', 'juror', 'system_parameter', 'juror_mod', 'system_parameter');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.system_parameter),
		expected_target_count = (select count(1) from juror.system_parameter)
where 	script_number = '0010';

do $$

begin

truncate table juror_mod.system_parameter;
	
with target
as
(
	insert into juror_mod.system_parameter(sp_id,sp_desc,sp_value,created_by,created_date,updated_by,updated_date)
	select distinct
			sp.sp_id,
			sp.sp_desc,
			sp.sp_value,
			sp.created_by,
			sp.created_date,
			sp.updated_by,
			sp.updated_date
	from juror.system_parameter sp
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(*) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0010';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0010';
end $$;

-- verify results
select * from juror_mod.migration_log where script_number = '0010';
select * from juror_mod.system_parameter limit 10;
