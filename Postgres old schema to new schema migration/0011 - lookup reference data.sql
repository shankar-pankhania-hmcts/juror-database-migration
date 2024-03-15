/*
 * +---------------+---------------+--------------------+---------------+-------------------------+
 * | Script Number | Source Schema |    Source Table    | Target Schema |      Target Table       |
 * +---------------+---------------+--------------------+---------------+-------------------------+
 * | 0011a         | juror         | t_phone            | juror_mod     | t_contact               |
 * | 0011b         | juror         | contact_preference | juror_mod     | t_contact_preference    |
 * | 0011c         | juror         | t_special          | juror_mod     | t_reasonable_adjustments|
 * | 0011d         | juror         | dis_code           | juror_mod     | t_disq_code             |
 * | 0011e         | juror         | exc_code           | juror_mod     | t_exc_code              |
 * | 0011f         | juror         | form_attr          | juror_mod     | t_form_attr             |
 * | 0011g         | juror         | t_history_code     | juror_mod     | t_history_code          |
 * | 0011h         | juror         | t_id_check         | juror_mod     | t_id_check              |
 * | 0011i         | juror         | pool_status        | juror_mod     | t_juror_status          |
 * | 0011j         | juror         | t_message_template | juror_mod     | t_message_template      |
 * | 0011k         | juror         | pool_type          | juror_mod     | t_pool_type             |
 * +---------------+---------------+--------------------+---------------+-------------------------+
 * 
 * lookup/reference data
 * ---------------------
 * 
 */

delete from juror_mod.migration_log where script_number like '0011%';

-- migrate juror.t_phone to juror_mod.t_contact

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0011a', 'juror', 't_phone', 'juror_mod', 't_contact');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.t_phone),
		expected_target_count = (select count(1) from juror.t_phone)
where 	script_number = '0011a';

do $$

begin
	
alter table juror_mod.contact_log
	drop constraint t_contact_fk;

truncate table juror_mod.t_contact;

with target
as
(
	insert into juror_mod.t_contact(enquiry_code, description)
	select distinct 
			p.phone_code,
			p.description
	from juror.t_phone p
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0011a';

alter table juror_mod.contact_log
	add constraint t_contact_fk foreign key (enquiry_type) references juror_mod.t_contact(enquiry_code);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0011a';
end $$;

-- migrate juror.contact_preference to juror_mod.t_contact_preference

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0011b', 'juror', 'contact_preference', 'juror_mod', 't_contact_preference');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.contact_preference),
		expected_target_count = (select count(1) from juror.contact_preference)
where 	script_number = '0011b';

do $$

begin
	
alter table juror_mod.juror
	drop constraint if exists t_contact_preference_fk;

truncate table juror_mod.t_contact_preference;

with target
as
(
	insert into juror_mod.t_contact_preference(id, contact_type, description)
	select distinct 
			cp.id, 
			cp."type", 
			cp.description
	from juror.contact_preference cp
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0011b';


alter table juror_mod.juror
	add constraint t_contact_preference_fk foreign key (contact_preference) references juror_mod.t_contact_preference(id);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0011b';
end $$;

-- migrate juror.t_special to juror_mod.t_reasonable_adjustments

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0011c', 'juror', 't_special', 'juror_mod', 't_reasonable_adjustments');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.t_special),
		expected_target_count = (select count(1) from juror.t_special)
where 	script_number = '0011c';

do $$

begin
	
alter table juror_mod.juror
	drop constraint if exists reasonable_adjustment_code_fk;
	
alter table juror_mod.juror_reasonable_adjustment
	drop constraint if exists juror_reasonable_adjustment_reasonable_adjustments_fkey;

truncate juror_mod.t_reasonable_adjustments;

with target as (
	insert into juror_mod.t_reasonable_adjustments(code, description)
	select distinct 
			s.spec_need,
			s.description
	from juror.t_special s
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0011c';


alter table juror_mod.juror add constraint reasonable_adjustment_code_fk foreign key (reasonable_adj_code) 
	references juror_mod.t_reasonable_adjustments(code);
	

alter table juror_mod.juror_reasonable_adjustment add constraint juror_reasonable_adjustment_reasonable_adjustments_fkey
	foreign key (reasonable_adjustment) references juror_mod.t_reasonable_adjustments(code);	

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0011c';
end $$;

-- migrate juror.dis_code to juror_mod.t_disq_code

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0011d', 'juror', 'dis_code', 'juror_mod', 't_disq_code');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.dis_code),
		expected_target_count = (select count(1) from juror.dis_code)
where 	script_number = '0011d';

do $$

begin
	
alter table juror_mod.juror
	drop constraint if exists disq_code_fk;

truncate juror_mod.t_disq_code;

with target as (
	insert into juror_mod.t_disq_code(disq_code, description, enabled)
	select distinct 
			d.disq_code,
			d.description,
			case when upper(d.enabled) = 'Y' then true else false end
	from juror.dis_code d
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0011d';


alter table juror_mod.juror add constraint disq_code_fk foreign key (disq_code) 
	references juror_mod.t_disq_code(disq_code);
	

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0011d';
end $$;

-- migrate juror.exc_code to juror_mod.t_exc_code

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0011e', 'juror', 'exc_code', 'juror_mod', 't_exc_code');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.exc_code),
		expected_target_count = (select count(1) from juror.exc_code)
where 	script_number = '0011e';

do $$

begin
	
alter table juror_mod.juror
	drop constraint if exists excusal_code_fk;

truncate juror_mod.t_exc_code;

with target as (
	insert into juror_mod.t_exc_code(exc_code, description, by_right, enabled)
	select distinct 
			e.exc_code,
			e.description,
			case when upper(e.by_right) = 'Y' then true else false end,
			case when upper(e.enabled) = 'Y' then true else false end
	from juror.exc_code e
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0011e';


alter table juror_mod.juror add constraint excusal_code_fk foreign key (excusal_code) 
	references juror_mod.t_exc_code(exc_code);
	

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0011e';
end $$;

-- migrate juror.form_attr to juror_mod.t_form_attr

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0011f', 'juror', 'form_attr', 'juror_mod', 't_form_attr');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.form_attr),
		expected_target_count = (select count(1) from juror.form_attr)
where 	script_number = '0011f';

do $$

begin
	
alter table juror_mod.bulk_print_data 
	drop constraint if exists bulk_print_data_fk_form_type;
	
alter table juror_mod.notify_template_mapping
	drop constraint if exists t_form_attr_fkey;

truncate juror_mod.t_form_attr;

with target as (
	insert into juror_mod.t_form_attr(form_type, dir_name, max_rec_len)
	select distinct 
			f.form_type,
			f.dir_name,
			f.max_rec_len
	from juror.form_attr f
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0011f';


alter table juror_mod.bulk_print_data add constraint bulk_print_data_fk_form_type foreign key (form_type) 
	references juror_mod.t_form_attr(form_type);

alter table juror_mod.notify_template_mapping add constraint t_form_attr_fkey foreign key (form_type) 
	references juror_mod.t_form_attr(form_type);
	

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0011f';
end $$;

-- migrate juror.t_history_code to juror_mod.t_history_code

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0011g', 'juror', 't_history_code', 'juror_mod', 't_history_code');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.t_history_code),
		expected_target_count = (select count(1) from juror.t_history_code)
where 	script_number = '0011g';

do $$

begin
	
alter table juror_mod.juror_history 
	drop constraint if exists juror_history_hist_code_fk;
	
alter table juror_mod.pool_history
	drop constraint if exists pool_history_fk;

truncate juror_mod.t_history_code;

with target as (
	insert into juror_mod.t_history_code(history_code, description)
	select distinct 
			hc.history_code,
			hc.description
	from juror.t_history_code hc
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0011g';


alter table juror_mod.juror_history add constraint juror_history_hist_code_fk foreign key (history_code) 
	references juror_mod.t_history_code(history_code);

alter table juror_mod.pool_history add constraint pool_history_fk foreign key (history_code) 
	references juror_mod.t_history_code(history_code);
	

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0011g';
end $$;

-- migrate juror.t_id_check to juror_mod.t_id_check

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0011h', 'juror', 't_id_check', 'juror_mod', 't_id_check');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.t_id_check),
		expected_target_count = (select count(1) from juror.t_id_check)
where 	script_number = '0011h';

do $$

begin
	
alter table juror_mod.juror_pool 
	drop constraint if exists juror_pool_t_id_check_fk;

truncate juror_mod.t_id_check;

with target as (
	insert into juror_mod.t_id_check(id_check, description)
	select distinct 
			ic.id_check,
			ic.description
	from juror.t_id_check ic
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0011h';


alter table juror_mod.juror_pool add constraint juror_pool_t_id_check_fk foreign key (id_checked) 
	references juror_mod.t_id_check(id_check);
	

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0011h';
end $$;

-- migrate juror.pool_status to juror_mod.t_juror_status

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0011i', 'juror', 'pool_status', 'juror_mod', 't_juror_status');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.pool_status),
		expected_target_count = (select count(1) from juror.pool_status)
where 	script_number = '0011i';

do $$

begin
	
alter table juror_mod.juror_pool 
	drop constraint if exists juror_pool_status_fk;

truncate juror_mod.t_juror_status;

with target as (
	insert into juror_mod.t_juror_status(status, status_desc, active)
	select distinct 
			p.status,
			p.status_desc,
			case when upper(p.active) = 'Y' then true else false end
	from juror.pool_status p
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0011i';


alter table juror_mod.juror_pool add constraint juror_pool_status_fk foreign key (status) 
	references juror_mod.t_juror_status(status);
	

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0011i';
end $$;

-- migrate juror.t_message_template to juror_mod.t_message_template

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0011j', 'juror', 't_message_template', 'juror_mod', 't_message_template');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.t_message_template),
		expected_target_count = (select count(1) from juror.t_message_template)
where 	script_number = '0011j';

do $$

begin
	
alter table juror_mod.message_to_placeholders 
	drop constraint if exists message_id_fk;

truncate juror_mod.t_message_template;

with target as (
	insert into juror_mod.t_message_template(id, "scope", title, subject, "text", display_order)
	select distinct 
			m.message_id,
			m.message_scope,
			m.message_title,
			m.message_subject,
			m.message_text,
			m.display_order
	from juror.t_message_template m
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0011j';


alter table juror_mod.message_to_placeholders add constraint message_id_fk foreign key (message_id) 
	references juror_mod.t_message_template(id);
	

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0011j';
end $$;

-- migrate juror.pool_type to juror_mod.t_pool_type

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0011k', 'juror', 'pool_type', 'juror_mod', 't_pool_type');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.pool_type),
		expected_target_count = (select count(1) from juror.pool_type)
where 	script_number = '0011k';

do $$

begin
	
alter table juror_mod.pool 
	drop constraint if exists pool_pool_type_fk;


truncate juror_mod.t_pool_type;

with target as (
	insert into juror_mod.t_pool_type(pool_type, pool_type_desc)
	select distinct 
		p.pool_type,
		p.pool_type_desc
	from juror.pool_type p
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0011k';


alter table juror_mod.pool add constraint pool_pool_type_fk foreign key (pool_type) 
	references juror_mod.t_pool_type(pool_type);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0011k';
end $$;


select * from juror_mod.migration_log where script_number LIKE '0011%' order by script_number;
select * from juror_mod.t_contact limit 10;
select * from juror_mod.t_contact_preference limit 10;
select * from juror_mod.t_reasonable_adjustments limit 10;
select * from juror_mod.t_disq_code limit 10;
select * from juror_mod.t_exc_code limit 10;
select * from juror_mod.t_form_attr limit 10;
select * from juror_mod.t_history_code limit 10;
select * from juror_mod.t_id_check limit 10;
select * from juror_mod.t_juror_status limit 10;
select * from juror_mod.t_message_template limit 10;
select * from juror_mod.t_pool_type limit 10;