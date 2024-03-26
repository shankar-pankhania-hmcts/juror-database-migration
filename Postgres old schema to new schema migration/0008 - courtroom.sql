/*
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0008 | juror         | location     | juror_mod     | courtroom    |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * courtroom
 * ---------
 * 
 */

delete from juror_mod.migration_log where script_number = '0008';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0008', 'juror', 'location', 'juror_mod', 'courtroom');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror."location"),
		expected_target_count = (select count(1) from juror."location")
where 	script_number = '0008';

do $$

begin

alter table juror_mod.court_location
	drop constraint if exists assembly_room_fk_assembly_room;
	
alter table juror_mod.courtroom
	drop constraint if exists courtroom_loc_code_fk;

alter table juror_mod.trial 
	drop constraint if exists trial_courtroom_fk;

truncate table juror_mod.courtroom;


with target as (
	insert into juror_mod.courtroom(loc_code,room_number,description)
	select distinct 
			l."owner",
			l."location",
			l.description
	from juror."location" l
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(*) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0008';


alter table juror_mod.court_location add constraint assembly_room_fk_assembly_room
	foreign key (assembly_room) references juror_mod.courtroom(id);

alter table juror_mod.courtroom add constraint  courtroom_loc_code_fk
	foreign key (loc_code) references juror_mod.court_location(loc_code);

alter table juror_mod.trial add constraint trial_courtroom_fk 
	foreign key (courtroom) references juror_mod.courtroom(id);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0008';

end $$;

-- verify results
select * from juror_mod.migration_log where script_number = '0008';
select * from juror_mod.courtroom limit 10;
