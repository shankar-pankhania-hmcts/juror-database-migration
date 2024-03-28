/*
 * 
 * +---------------+---------------+-------------------------+---------------+-------------------------+
 * | Script Number | Source Schema |      Source Table       | Target Schema |      Target Table       |
 * +---------------+---------------+-------------------------+---------------+-------------------------+
 * | 0022a         | juror_digital | notify_template_mapping | juror_mod     | notify_template_mapping |
 * | 0022b         | juror_digital | notify_template_field   | juror_mod     | notify_template_field   |
 * | 0022c         | juror_digital | region_notify_template  | juror_mod     | region_notify_template  |
 * +---------------+---------------+-------------------------+---------------+-------------------------+
 * 
 * notify_template_mapping
 * -----------------------
 */

delete from juror_mod.migration_log where script_number like '0022%';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0022a', 'juror_digital', 'notify_template_mapping', 'juror_mod', 'notify_template_mapping', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.notify_template_mapping),
		expected_target_count = (select count(1) from juror_digital.notify_template_mapping)
where 	script_number = '0022a';

do $$

begin

truncate table juror_mod.notify_template_mapping;

with target as
(
 	insert into juror_mod.notify_template_mapping (form_type,notification_type,notify_name,template_id,template_name,version)
	select distinct 
			ntm.form_type,
			ntm.notification_type,
			ntm.notify_name,
			ntm.template_id,
			ntm.template_name,
			ntm."version"
	from juror_digital.notify_template_mapping ntm
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0022a';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0022a';
	
end $$;

-- notify_template_field
-------------------------

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0022b', 'juror_digital', 'notify_template_field', 'juror_mod', 'notify_template_field', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.notify_template_field),
		expected_target_count = (select count(1) from juror_digital.notify_template_field)
where 	script_number = '0022b';

do $$

begin

truncate table juror_mod.notify_template_field;

with target as (
 	insert into juror_mod.notify_template_field (id,convert_to_date,database_field,field_length,jd_class_name,jd_class_property,position_from,position_to,template_field,template_id,"version")
	select distinct 
			ntf.id,
			case ntf.convert_to_date
				when 'Y'
					then true
					else false
			end as convert_to_date,
			ntf.database_field,
			ntf.field_length,
			ntf.jd_class_name,
			ntf.jd_class_property,
			ntf.position_from,
			ntf.position_to,
			ntf.template_field,
			ntf.template_id,
			ntf."version"
	from juror_digital.notify_template_field ntf
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0022b';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0022b';
	
end $$;



-- region_notify_template
-------------------------


insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0022c', 'juror_digital', 'region_notify_template', 'juror_mod', 'region_notify_template', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.region_notify_template),
		expected_target_count = (select count(1) from juror_digital.region_notify_template)
where 	script_number = '0022c';

do $$

begin

truncate table juror_mod.region_notify_template;

with target as (
 	insert into juror_mod.region_notify_template (legacy_template_id,message_format,notify_template_id,region_id,region_template_id,template_name,triggered_template_id,welsh_language)
	select distinct 
			rnt.legacy_template_id,
			rnt.message_format,
			rnt.notify_template_id,
			rnt.region_id,
			rnt.region_template_id,
			rnt.template_name,
			rnt.triggered_template_id,
			rnt.welsh_language
	from juror_digital.region_notify_template rnt
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0022c';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0022c';
	
end $$; 

-- verify results
select * from juror_mod.migration_log where script_number like '0022%' order by script_number;
select * from juror_mod.notify_template_mapping limit 10;
select * from juror_mod.notify_template_field limit 10;
select * from juror_mod.region_notify_template limit 10;