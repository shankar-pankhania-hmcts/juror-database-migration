/*
 * 
 * +---------------+---------------+--------------+---------------+---------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table  |
 * +---------------+---------------+--------------+---------------+---------------+
 * |          0025 | juror         | manuals      | juror_mod     | pending_juror |
 * +---------------+---------------+--------------+---------------+---------------+
 * 
 * pending_juror
 * -------------
 */

delete from juror_mod.migration_log where script_number = '0025';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0025', 'juror', 'manuals', 'juror_mod', 'pending_juror', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.manuals),
		expected_target_count = (select count(1) from juror.manuals)
where 	script_number = '0025';

do $$

begin

alter table juror_mod.pending_juror
	drop constraint if exists pending_juror_status_fk;

truncate table juror_mod.pending_juror;

with target as (
	insert into juror_mod.pending_juror(juror_number,pool_number,title,last_name,first_name,dob,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode,h_phone,w_phone,w_ph_local,m_phone,h_email,contact_preference,responded,next_date,date_added,mileage,pool_seq,status,is_active,added_by,notes,date_created)
	select distinct
			m.part_no,
			m.pool_no,
			m.title,
			m.lname,
			m.fname,
			m.dob,
			coalesce(m.address,'') as address1,
			m.address2,
			m.address3,
			coalesce(m.address4,'') as address4,
			m.address5,
			m.zip,
			m.h_phone,
			m.w_phone,
			m.w_ph_local,
			m.m_phone,
			m.h_email,
			m.contact_preference,
			case upper(m.responded)
				when 'Y'
					then true
					else false
			end as responded,
			m.next_date,
			m.date_added,			
			m.mileage,
			m.pool_seq,
			m.pool_status,
			case upper(m.is_active)
				when 'Y'
					then true
					else false
			end as is_active,
			m.added_by,
			m.notes,
			(select min(ph."date_part") from juror.part_hist ph where ph.part_no = m.part_no) as date_created  -- take first entry in juror history
	from juror.manuals m
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0025';


alter table juror_mod.pending_juror 
	add constraint pending_juror_status_fk foreign key (status) references juror_mod.t_pending_juror_status(code);



exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0025';
	
end $$;

-- verify results
select * from juror_mod.migration_log where script_number = '0025';
select * from juror_mod.pending_juror limit 10;