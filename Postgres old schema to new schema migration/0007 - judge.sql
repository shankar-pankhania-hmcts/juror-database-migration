/*
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0007 | juror         | judge        | juror_mod     | judge        |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * judge
 * -----
 * 
 */

delete from juror_mod.migration_log where script_number = '0007';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0007', 'juror', 'judge', 'juror_mod', 'judge');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.judge),
		expected_target_count = (select count(1) from juror.judge)
where 	script_number = '0007';

do $$

begin

alter table juror_mod.trial 
	drop constraint if exists trial_judge_fk;

truncate table juror_mod.judge;

with target
as
(
	insert into juror_mod.judge("owner",code,description,telephone_number)
	select distinct 
			j."owner",
			j.judge,
			j.description,
			j.tel_no
	from juror.judge j
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0007';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0007';
	
alter table juror_mod.trial 
	add constraint trial_judge_fk foreign key (judge) references juror_mod.judge(id) not valid;

end $$;

-- verify results
select * from juror_mod.migration_log where script_number = '0007';
select * from juror_mod.judge limit 10;
