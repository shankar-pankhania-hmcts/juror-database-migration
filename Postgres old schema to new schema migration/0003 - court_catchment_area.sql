/*
 * +---------------+---------------+----------------------+---------------+----------------------+
 * | Script Number | Source Schema |     Source Table     | Target Schema |     Target Table     |
 * +---------------+---------------+----------------------+---------------+----------------------+
 * |          0003 | juror         | court_catchment_area | juror_mod     | court_catchment_area |
 * +---------------+---------------+----------------------+---------------+----------------------+
 * 
 * COURT_CATCHMENT_AREA
 * --------------------
 * 
 */

delete from juror_mod.migration_log where script_number = '0003';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0003', 'juror', 'court_catchment_area', 'juror_mod', 'court_catchment_area');




update	juror_mod.migration_log
set		source_count = (select count(1) as source_count from juror.court_catchment_area),
		expected_target_count = (select count(1) as source_count from juror.court_catchment_area)
where 	script_number = '0003';


do $$

begin

alter table juror_mod.court_catchment_area 
	drop constraint if exists court_catchment_area_fk_loc_code;
	
truncate table juror_mod.court_catchment_area;

with "target"
as
(
	insert into juror_mod.court_catchment_area(postcode,loc_code)
	select 	cca.postcode,
			cca.loc_code
	from juror.court_catchment_area cca
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from "target"),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0003';


alter table juror_mod.court_catchment_area 
	add constraint court_catchment_area_fk_loc_code foreign key (loc_code) references juror_mod.court_location(loc_code) not valid;

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0003';
end $$;


select * from juror_mod.migration_log where script_number = '0003';
select * from juror_mod.court_catchment_area limit 10;
