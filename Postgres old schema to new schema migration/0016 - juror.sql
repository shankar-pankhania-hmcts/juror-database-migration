/*
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0016 | juror         | pool         | juror_mod     | juror        |
 * +---------------+---------------+--------------+---------------+--------------+
 *  
 * juror
 * -----
 */

delete from juror_mod.migration_log where script_number = '0016';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0016', 'juror', 'pool', 'juror_mod', 'juror');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.pool),
		expected_target_count = (select count(distinct part_no) from juror.pool where read_only = 'N')
where 	script_number = '0016';

do $$

begin
	
-- drop indexes to improve performance

drop index if exists juror_mod.last_name_1;
drop index if exists juror_mod.i_zip_1; 

	
-- drop foreign key constraints

alter table juror_mod.appearance
   drop constraint if exists appearance_juror_fk; 

alter table juror_mod.juror_response
   drop constraint if exists juror_response_juror_number_fkey;

alter table juror_mod.bulk_print_data
   drop constraint if exists bulk_print_data_juror_no_fk;

alter table juror_mod.contact_log
   drop constraint if exists juror_number_fk;

alter table juror_mod.juror_pool
   drop constraint if exists juror_pool_fk_juror; 

alter table juror_mod.juror_history
   drop constraint if exists juror_history_fk;

alter table juror_mod.juror
   drop constraint if exists police_check_val;

-- begin data migration

truncate juror_mod.juror;

with last_updated as (
	select distinct
			p.part_no, 
			p.pool_no,
			p."owner",
			p.last_update,
			row_number() over (partition by p.part_no 
				order by p.part_no, p.last_update desc) as row_no -- identify the last record updated for the juror
	from juror.pool p
	where p.read_only = 'N')
	
, target as (
	insert into juror_mod.juror(juror_number,poll_number,title,last_name,first_name,dob,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode,h_phone,w_phone,w_ph_local,responded,date_excused,excusal_code,acc_exc,date_disq,disq_code,user_edtq,notes,no_def_pos,perm_disqual,smart_card_number,completion_date,sort_code,bank_acct_name,bank_acct_no,bldg_soc_roll_no,welsh,police_check,last_update,summons_file,m_phone,h_email,contact_preference,notifications,optic_reference,date_created,travel_time,claiming_subsistence_allowance)
	select distinct 
			p.part_no,
			p.poll_number as poll_number,
			p.title as title,
			p.lname as last_name,
			p.fname as first_name,
			p.dob as dob,
			p.address as address_line_1,
			p.address2 as address_line_2,
			p.address3 as address_line_3,
			p.address4 as address_line_4,
			rtrim(p.address5||' '||p.address6) as address_line_5,
			p.zip as postcode,
			p.h_phone as h_phone,
			p.w_phone as w_phone,
			p.w_ph_local as w_ph_local,
			case upper(p.responded)
				when 'Y' 
					then true
					else false
			end as responded,
			p.date_excus as date_excused,
			p.exc_code as excusal_code,
			p.acc_exc as acc_exc,
			p.date_disq as date_disq,
			p.disq_code as disq_code,
			p.user_edtq as user_edtq,
			p.notes as notes,
			p.no_def_pos as no_def_pos,
			case upper(p.perm_disqual)
				when 'Y' 
					then true
					else false
			end as perm_disqual,
			p.smart_card as smart_card_number,
			p.completion_date as completion_date,
			p.sort_code as sort_code,
			p.bank_acct_name as bank_acct_name,
			p.bank_acct_no as bank_acct_no,
			p.bldg_soc_roll_no as bldg_soc_roll_no,
			case upper(p.welsh)
				when 'Y' 
					then true
					else false
			end as welsh,
			case 
				when p.police_check = 'E'
					then 'IN_PROGRESS'
				when p.police_check = 'P' and p.phoenix_checked = 'C'
					then 'ELIGIBLE'
				when p.police_check = 'C' and p.phoenix_checked = 'F'
					then 'INELIGIBLE'
				when p.phoenix_checked = 'U'
					then 'UNCHECKED_MAX_RETRIES_EXCEEDED'
				when p.police_check = 'I' 
					then 'INSUFFICIENT_INFORMATION'
					else null
			end as police_check,
			p.last_update as last_update,
			p.summons_file as summons_file,
			p.m_phone as m_phone,
			p.h_email as h_email,
			p.contact_preference as contact_preference,
			p.notifications as notifications,
			null as optic_reference,
			lu.last_update as last_update,
			p.travel_time*'1 HOUR'::interval as travel_time_time,
			false AS claiming_subsistence_allowance -- new "juror defaults" value, screen designs show this as defaulted to false
	from juror.pool p
	join last_updated lu  
	on p.part_no = lu.part_no
	and p.pool_no = lu.pool_no
	and p."owner" = lu."owner"
	and p.last_update = lu.last_update
	and lu.row_no = 1  -- required to filter out duplicates - return only the latest update for the juror
	where p.read_only = 'N'
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0016';

-- re-apply foreign key constraints

alter table juror_mod.appearance
   add constraint appearance_juror_fk foreign key (juror_number) references juror_mod.juror(juror_number) not valid;

alter table juror_mod.juror_response
   add constraint juror_response_juror_number_fkey foreign key (juror_number) references juror_mod.juror(juror_number)  not valid;

alter table juror_mod.bulk_print_data
   add constraint bulk_print_data_juror_no_fk foreign key (juror_no) references juror_mod.juror(juror_number) not valid;

alter table juror_mod.contact_log
   add constraint juror_number_fk foreign key (juror_number) references juror_mod.juror(juror_number) not valid;

alter table juror_mod.juror_pool
   add constraint juror_pool_fk_juror foreign key (juror_number) references juror_mod.juror(juror_number) not valid;
  
alter table juror_mod.juror_history
   add constraint juror_history_fk foreign key (juror_number) references juror_mod.juror(juror_number) not valid;

alter table juror_mod.juror 
	add constraint police_check_val check (((police_check)::text = any ((array[
	'INSUFFICIENT_INFORMATION'::character varying, 
	'NOT_CHECKED'::character varying, 
	'IN_PROGRESS'::character varying, 
	'ELIGIBLE'::character varying, 
	'INELIGIBLE'::character varying, 
	'ERROR_RETRY_NAME_HAS_NUMERICS'::character varying, 
	'ERROR_RETRY_CONNECTION_ERROR'::character varying, 
	'ERROR_RETRY_OTHER_ERROR_CODE'::character varying, 
	'ERROR_RETRY_NO_ERROR_REASON'::character varying, 
	'ERROR_RETRY_UNEXPECTED_EXCEPTION'::character varying, 
	'UNCHECKED_MAX_RETRIES_EXCEEDED'::character varying])::text[])));

-- rebuild indexes

create index i_zip_1 on juror_mod.juror using btree (postcode);
create index last_name_1 on juror_mod.juror using btree (last_name);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0016';
	
end $$;
  
-- verify results
select * from juror_mod.migration_log where script_number like '0016' order by script_number;
select * from juror_mod.pool limit 10;
