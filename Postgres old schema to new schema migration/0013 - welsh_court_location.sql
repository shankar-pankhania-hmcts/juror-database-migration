/*
 * +---------------+---------------+----------------+---------------+----------------------+
 * | Script Number | Source Schema |  Source Table  | Target Schema |     Target Table     |
 * +---------------+---------------+----------------+---------------+----------------------+
 * |          0013 | juror         | welsh_location | juror_mod     | welsh_court_location |
 * +---------------+---------------+----------------+---------------+----------------------+
 * 
 * welsh_court_location
 * --------------------
 * 
 */

delete from juror_mod.migration_log where script_number = '0013';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0013', 'juror', 'welsh_location', 'juror_mod', 'welsh_court_location');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.welsh_location),
		expected_target_count = (select count(1) from juror.welsh_location)
where 	script_number = '0013';

do $$

begin

truncate table juror_mod.welsh_court_location;

with target
as
(
	insert into juror_mod.welsh_court_location(loc_code, loc_name, loc_address1, loc_address2, loc_address3, loc_address4, loc_address5, loc_address6, location_address)
	select distinct 
			wl.loc_code,
			wl.loc_name,
			wl.loc_address1,
			wl.loc_address2,
			wl.loc_address3,
			wl.loc_address4,
			wl.loc_address5,
			wl.loc_address6,
			wl.location_address
	from juror.welsh_location wl
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0013';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0013';
end $$;

select * from juror_mod.migration_log where script_number = '0013';
select * from juror_mod.welsh_court_location limit 10;