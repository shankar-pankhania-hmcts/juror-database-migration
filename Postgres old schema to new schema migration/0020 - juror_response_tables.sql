/*
 * 
 * +---------------+---------------+-------------------------------+---------------+-------------------------------+
 * | Script Number | Source Schema |         Source Table          | Target Schema |         Target Table          |
 * +---------------+---------------+-------------------------------+---------------+-------------------------------+
 * | 0020a         | juror_digital | juror_response                | juror_mod     | juror_response                |
 * | 0020b         | juror_digital | juror_special_needs           | juror_mod     | juror_reasonable_adjustments  |
 * | 0020c         | juror_digital | juror_response_aud            | juror_mod     | juror_response_aud            |
 * | 0020d         | juror_digital | juror_response_cjs_employment | juror_mod     | juror_response_cjs_employment |
 * | 0020e         | juror_digital | staff_juror_response_audit    | juror_mod     | staff_juror_response_audit    |
 * +---------------+---------------+-------------------------------+---------------+-------------------------------+
 * 
 * juror_response
 * --------------
 */

delete from juror_mod.migration_log where script_number like '0020%';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0020a', 'juror_digital', 'juror_response', 'juror_mod', 'juror_response', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.juror_response),
		expected_target_count = (select count(distinct juror_number) from juror_digital.juror_response)
where 	script_number = '0020a';

do $$

begin

alter table juror_mod.juror_response 
	drop constraint if exists juror_response_juror_number_fkey;

alter table juror_mod.juror_response 
	drop constraint if exists juror_response_reply_type_fkey;


truncate table juror_mod.juror_response;

with target as (
 	insert into juror_mod.juror_response (juror_number,first_name,last_name,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode,alt_phone_number,bail,bail_details,completed_at,convictions,convictions_details,date_of_birth,date_received,deferral_date,deferral_reason,email,email_address,excusal_reason,juror_email_details,juror_phone_details,main_phone,mental_health_act,mental_health_act_details,other_phone,phone_number,processing_complete,processing_status,relationship,residency,residency_detail,staff_assignment_date,staff_login,thirdparty_fname,thirdparty_lname,thirdparty_other_reason,thirdparty_reason,title,urgent,super_urgent,welsh,"version",reply_type,reasonable_adjustments_arrangements)
	select distinct 
			jr.juror_number,
			jr.first_name,
			jr.last_name,
			jr.address,
			jr.address2,
			jr.address3,
			jr.address4,
			rtrim(jr.address5||' '||jr.address6) as address5,
			jr.zip,
			jr.alt_phone_number,
			case upper(jr.bail)
				when 'Y' 
					then true
					else false
			end,
			jr.bail_details,
			jr.completed_at,
			case upper(jr.convictions)
				when 'Y' 
					then true
					else false
			end,
			jr.convictions_details,
			jr.date_of_birth,
			jr.date_received,
			jr.deferral_date,
			jr.deferral_reason,
			jr.email,
			jr.email_address,
			jr.excusal_reason,
			case upper(jr.juror_email_details)
				when 'Y' 
					then true
					else false
			end,
			case upper(jr.juror_phone_details)
				when 'Y' 
					then true
					else false
			end,
			jr.main_phone,
			case upper(jr.mental_health_act)
				when 'Y' 
					then true
					else false
			end,
			jr.mental_health_act_details,
			jr.other_phone,
			jr.phone_number,
			case upper(jr.processing_complete)
				when 'Y' 
					then true
					else false
			end,
			jr.processing_status,
			jr.relationship,
			case upper(jr.residency)
				when 'Y' 
					then true
					else false
			end,
			jr.residency_detail,
			jr.staff_assignment_date,
			jr.staff_login,
			jr.thirdparty_fname,
			jr.thirdparty_lname,
			jr.thirdparty_other_reason,
			jr.thirdparty_reason,
			jr.title,
			case upper(jr.urgent)
				when 'Y' 
					then true
					else false
			end,
			case upper(jr.super_urgent)
				when 'Y' 
					then true
					else false
			end,
			case upper(jr.welsh)
				when 'Y' 
					then true
					else false
			end,
			jr."version",
			'Digital' as reply_type,
			jr.special_needs_arrangements
	from juror_digital.juror_response jr
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0020a';

alter table juror_mod.juror_response
	add constraint juror_response_juror_number_fkey foreign key (juror_number) references juror_mod.juror(juror_number);

alter table juror_mod.juror_response
	add constraint juror_response_reply_type_fkey foreign key (reply_type) references juror_mod.t_reply_type("type");


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0020a';
	
end $$;


-- juror_reasonable_adjustment

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0020b', 'juror_digital', 'juror_response_special_needs', 'juror_mod', 'juror_reasonable_adjustment', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.juror_response_special_needs),
		expected_target_count = (select count(1) from juror_digital.juror_response_special_needs)
where 	script_number = '0020b';

do $$

begin


alter table juror_mod.juror_reasonable_adjustment 
	drop constraint if exists juror_reasonable_adjustment_juror_number_fkey;

truncate juror_mod.juror_reasonable_adjustment restart identity cascade;

with target as (
	insert into juror_mod.juror_reasonable_adjustment(juror_number,reasonable_adjustment,reasonable_adjustment_detail)
	select distinct 
			jrsn.juror_number,
			jrsn.spec_need,
			jrsn.spec_need_detail
	from juror_digital.juror_response_special_needs jrsn
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0020b';


alter table juror_mod.juror_reasonable_adjustment
	add constraint juror_reasonable_adjustment_juror_number_fkey foreign key (juror_number) references juror_mod.juror_response(juror_number);


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0020b';
	
end $$;



-- juror_response_aud

truncate juror_mod.juror_response_aud;

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0020c', 'juror_digital', 'juror_response_aud', 'juror_mod', 'juror_response_aud', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.juror_response_aud),
		expected_target_count = (select count(1) from juror_digital.juror_response_aud)
where 	script_number = '0020c';

do $$

begin

alter table juror_mod.juror_response_aud 
	drop constraint if exists juror_response_aud_juror_number_fkey;

with target as (
	insert into juror_mod.juror_response_aud(changed,juror_number,login,new_processing_status,old_processing_status)
	select distinct 
			jra.changed,
			jra.juror_number,
			jra.login,
			jra.new_processing_status,
			jra.old_processing_status
	from juror_digital.juror_response_aud jra
	returning 1
)

 
update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0020c';

alter table juror_mod.juror_response_aud
	add constraint juror_response_aud_juror_number_fkey foreign key (juror_number) references juror_mod.juror_response(juror_number);


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0020c';
	
end $$;

-- juror_response_cjs_employment

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0020d', 'juror_digital', 'juror_response_cjs_employment', 'juror_mod', 'juror_response_cjs_employment', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.juror_response_cjs_employment),
		expected_target_count = (select count(1) from juror_digital.juror_response_cjs_employment)
where 	script_number = '0020d';

do $$

begin
	
alter table juror_mod.juror_response_cjs_employment 
	drop constraint if exists juror_response_cjs_employment_juror_number_fkey;

truncate juror_mod.juror_response_cjs_employment restart identity cascade;

with target as (
	insert into juror_mod.juror_response_cjs_employment(juror_number,cjs_employer,cjs_employer_details)
	select distinct 
			jrce.juror_number,
			jrce.cjs_employer,
			jrce.cjs_employer_details
	from juror_digital.juror_response_cjs_employment jrce 
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0020d';

alter table juror_mod.juror_response_cjs_employment 
	add constraint juror_response_cjs_employment_juror_number_fkey foreign key (juror_number) references juror_mod.juror_response(juror_number) not valid;


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0020d';
	
end $$;

-- staff_juror_response_audit
-- TODO - update to new user model

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0020e', 'juror_digital', 'staff_juror_response_audit', 'juror_mod', 'staff_juror_response_audit', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.staff_juror_response_audit),
		expected_target_count = (select count(1) from juror_digital.staff_juror_response_audit)
where 	script_number = '0020e';

do $$

begin

alter table juror_mod.staff_juror_response_audit 
	drop constraint if exists staff_juror_response_audit_juror_number_fkey;

truncate juror_mod.staff_juror_response_audit;

with target as (
	insert into juror_mod.staff_juror_response_audit(juror_number,created,date_received,staff_assignment_date,staff_login,team_leader_login,"version")
	select distinct 
			sjra.juror_number,
			sjra.created,
			sjra.date_received,
			sjra.staff_assignment_date,
			sjra.staff_login,
			sjra.team_leader_login,
			sjra."version"
	from juror_digital.staff_juror_response_audit sjra
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0020e';

alter table juror_mod.staff_juror_response_audit
	add constraint staff_juror_response_audit_juror_number_fkey foreign key (juror_number) references juror_mod.juror_response(juror_number);


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0020e';
	
end $$;
 

-- verify results
select * from juror_mod.migration_log where script_number like '0020%' order by script_number;
select * from juror_mod.juror_response limit 10;
select * FROM juror_mod.juror_reasonable_adjustment limit 10;
select * FROM juror_mod.juror_response_aud limit 10;
select * FROM juror_mod.juror_response_cjs_employment limit 10;
select * from juror_mod.staff_juror_response_audit limit 10;