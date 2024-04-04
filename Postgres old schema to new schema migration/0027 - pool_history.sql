/*
 * 
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0027 | juror         | pool_hist    | juror_mod     | pool_history |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * pool_history
 * ------------
 */

delete from juror_mod.migration_log where script_number = '0027';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0027', 'juror', 'pool_hist', 'juror_mod', 'pool_history', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.pool_hist),
		expected_target_count = (select count(1) from (
			select distinct 
					ph.pool_no,
					ph.history_code,
					ph.user_id,
					ph.other_information,
					ph."date_part"
			from juror.pool_hist ph))
where 	script_number = '0027';

do $$

begin

alter table juror_mod.pool_history 
	drop constraint pool_history_fk;

truncate table juror_mod.pool_history restart identity cascade;

with target as (
 	insert into juror_mod.pool_history(pool_no,history_code,user_id,other_information,history_date)
	select distinct 
			ph.pool_no,
			ph.history_code,
			ph.user_id,
			ph.other_information,
			ph."date_part"
	from juror.pool_hist ph
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0027';


alter table juror_mod.pool_history 
	add constraint pool_history_fk foreign key (history_code) references juror_mod.t_history_code(history_code) not valid;


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0027';
	
end $$;

-- verify results
select * from juror_mod.migration_log where script_number = '0027';
select * from juror_mod.pool_history limit 10;