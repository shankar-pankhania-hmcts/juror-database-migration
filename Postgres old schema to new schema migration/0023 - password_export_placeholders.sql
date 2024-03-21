/*
 * 
 * +---------------+---------------+------------------------------+---------------+------------------------------+
 * | Script Number | Source Schema |         Source Table         | Target Schema |         Target Table         |
 * +---------------+---------------+------------------------------+---------------+------------------------------+
 * |          0023 | juror         | password_export_placeholders | juror_mod     | password_export_placeholders |
 * +---------------+---------------+------------------------------+---------------+------------------------------+
 * 
 * password_export_placeholders
 * ----------------------------
 */

delete from juror_mod.migration_log where script_number = '0023';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0023', 'juror', 'password_export_placeholders', 'juror_mod', 'password_export_placeholders', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.password_export_placeholders),
		expected_target_count = (select count(1) from juror.password_export_placeholders)
where 	script_number = '0023';

do $$

begin

truncate table juror_mod.password_export_placeholders;

with target as
(
	insert into juror_mod.password_export_placeholders("owner",login,placeholder_name,use)
	select distinct 
			pep."owner",
			pep.login,
			pep.placeholder_name,
			pep.use
	from juror.password_export_placeholders pep
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0023';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0023';
	
end $$;

-- verify results
select * from juror_mod.migration_log where script_number = '0023';
select * from juror_mod.password_export_placeholders limit 10;