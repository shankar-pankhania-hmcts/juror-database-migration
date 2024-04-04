/*
 * 
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0029 | juror         | phone_log    | juror_mod     | contact_log  |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * contact_log
 * -----------
 */

delete from juror_mod.migration_log where script_number = '0029';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0029', 'juror', 'phone_log', 'juror_mod', 'contact_log', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.phone_log),
		expected_target_count = (select count(1) from (
				select distinct 
						pl.part_no,
						pl.user_id,
						pl.start_call,
						pl.end_call,
						pl.phone_code,
						pl.notes,
						pl.last_update
				from juror.phone_log pl))
where 	script_number = '0029';

do $$

begin
	
alter table juror_mod.contact_log 
	drop constraint juror_number_fk;

truncate juror_mod.contact_log restart identity cascade;

with target as (
 	insert into juror_mod.contact_log (juror_number,user_id,start_call,end_call,enquiry_type,notes,last_update)
	select distinct 
			pl.part_no,
			pl.user_id,
			pl.start_call,
			pl.end_call,
			pl.phone_code,
			pl.notes,
			pl.last_update
	from juror.phone_log pl
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0029';

alter table juror_mod.contact_log 
	add constraint juror_number_fk foreign key (juror_number) references juror_mod.juror(juror_number) not valid;

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0029';
	
end $$;
	
-- verify results
select * from juror_mod.migration_log where script_number = '0029';
select * from juror_mod.contact_log limit 10;