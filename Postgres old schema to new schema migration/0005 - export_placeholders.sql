/*
 * +---------------+---------------+---------------------+---------------+---------------------+
 * | Script Number | Source Schema |    Source Table     | Target Schema |    Target Table     |
 * +---------------+---------------+---------------------+---------------+---------------------+
 * |          0005 | juror         | export_placeholders | juror_mod     | export_placeholders |
 * +---------------+---------------+---------------------+---------------+---------------------+
 * 
 * export_placeholders
 * -------------------
 * 
 */

delete from juror_mod.migration_log where script_number = '0005';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0005', 'juror', 'export_placeholders', 'juror_mod', 'export_placeholders');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.export_placeholders),
		expected_target_count = (select count(1) from juror.export_placeholders)
where 	script_number = '0005';

do $$

begin
	
truncate table juror_mod.export_placeholders;

with target
as
(
	insert into juror_mod.export_placeholders(placeholder_name,source_table_name,source_column_name,type,description,default_value,editable,validation_rule,validation_message,validation_format)
	select distinct 
			ep.placeholder_name,
			ep.source_table_name,
			ep.source_column_name,
			ep.type,
			ep.description,
			ep.default_value,
			ep.editable,
			ep.validation_rule,
			ep.validation_message,
			ep.validation_format
	from juror.export_placeholders ep
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(*) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0005';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0005';
end $$;

-- verify results
select * from juror_mod.migration_log where script_number = '0005';
select * from juror_mod.export_placeholders limit 10;
