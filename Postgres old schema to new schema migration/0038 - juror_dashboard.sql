/*
 *
 * +---------------+---------------+------------------------------+-----------------+------------------------------+
 * | Script Number | Source Schema |         Source Table         |  Target Schema  |         Target Table         |
 * +---------------+---------------+------------------------------+-----------------+------------------------------+
 * | 0038a         | juror_digital | stats_deferrals              | juror_dashboard | stats_deferrals              |
 * | 0038b         | juror_digital | stats_excusals               | juror_dashboard | stats_excusals               |
 * | 0038c         | juror_digital | stats_not_responded          | juror_dashboard | stats_not_responded          |
 * | 0038d         | juror_digital | stats_response_times         | juror_dashboard | stats_response_times         |
 * | 0038e         | juror_digital | stats_thirdparty_online      | juror_dashboard | stats_thirdparty_online      |
 * | 0038f         | juror_digital | stats_auto_processed         | juror_dashboard | stats_auto_processed         |
 * | 0038g         | juror_digital | stats_unprocessed_responses  | juror_dashboard | stats_unprocessed_responses  |
 * | 0038h         | juror_digital | survey_response              | juror_dashboard | survey_response              |
 * | 0038i         | juror_digital | stats_welsh_online_responses | juror_dashboard | stats_welsh_online_responses |
 * +---------------+---------------+------------------------------+-----------------+------------------------------+
 * 
 * stats_deferrals
 * ---------------
 */

delete from juror_mod.migration_log where script_number like '0038%';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0038a', 'juror', 'stats_deferrals', 'juror_mod', 'stats_deferrals', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.stats_deferrals),
		expected_target_count = (select count(1) from juror_digital.stats_deferrals)
where 	script_number = '0038a';

do $$

begin

truncate table juror_dashboard.stats_deferrals;

with target as (
insert into juror_dashboard.stats_deferrals(bureau_or_court, exc_code, calendar_year, financial_year, "week", deferral_count)
		select
			bureau_or_court,
			exec_code,
			calendar_year,
			financial_year,
			"week",
			excusal_count
		from
			juror_digital.stats_deferrals
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0038a';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0038a';

end $$;

/*
 * stats_excusals
 */

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0038b', 'juror', 'stats_excusals', 'juror_mod', 'stats_excusals', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.stats_excusals),
		expected_target_count = (select count(1) from juror_digital.stats_excusals)
where 	script_number = '0038b';

do $$

begin
	
truncate table juror_dashboard.stats_excusals;

with target 
as
(
	insert into juror_dashboard.stats_excusals(bureau_or_court,exc_code,calendar_year,financial_year,"week",excusal_count)
	select
		bureau_or_court,
		exec_code,
		calendar_year,
		financial_year,
		"week",
		excusal_count
	from juror_digital.stats_excusals
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0038b';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0038b';

end $$;

/*
 * stats_not_responded
 */

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0038c', 'juror', 'stats_not_responded', 'juror_mod', 'stats_not_responded', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.stats_not_responded),
		expected_target_count = (select count(1) from juror_digital.stats_not_responded)
where 	script_number = '0038c';

do $$

begin
	
truncate table juror_dashboard.stats_not_responded;

with target 
as
(	
	insert into juror_dashboard.stats_not_responded(summons_month,loc_code,not_responded_count)
	select
		summons_month,
		loc_code,
		non_responsed_count 
	from juror_digital.stats_not_responded	
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0038c';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0038c';

end $$;


/*
 * stats_response_times
 */

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0038d', 'juror', 'stats_response_times', 'juror_mod', 'stats_response_times', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.stats_response_times),
		expected_target_count = (select count(1) from juror_digital.stats_response_times)
where 	script_number = '0038d';

do $$

begin
	
truncate table juror_dashboard.stats_response_times;

with target as (	
	insert into juror_dashboard.stats_response_times(summons_month,response_month,response_period,loc_code,response_method,response_count)
	select
		summons_month,
		response_month,
		response_period,
		loc_code,
		response_method,
		response_count
	from
		juror_digital.stats_response_times
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0038d';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0038d';

end $$;

/*
 * stats_thirdparty_online
 */

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0038e', 'juror', 'stats_thirdparty_online', 'juror_mod', 'stats_thirdparty_online', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.stats_thirdparty_online),
		expected_target_count = (select count(1) from juror_digital.stats_thirdparty_online)
where 	script_number = '0038e';

do $$

begin
	
truncate table juror_dashboard.stats_thirdparty_online;

with target  as (	
	insert into juror_dashboard.stats_thirdparty_online(summons_month,thirdparty_response_count )
	select
		summons_month,
		thirdparty_response_count 
	from juror_digital.stats_thirdparty_online
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0038e';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0038e';

end $$;


/*
 * stats_auto_processed
 */

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0038f', 'juror', 'stats_auto_processed', 'juror_mod', 'stats_auto_processed', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.stats_auto_processed),
		expected_target_count = (select count(1) from juror_digital.stats_auto_processed)
where 	script_number = '0038f';

do $$

begin
	
truncate table juror_dashboard.stats_auto_processed;

with target  as (	
	insert into juror_dashboard.stats_auto_processed(processed_date,processed_count)
	select
		processed_date,
		processed_count
	from juror_digital.stats_auto_processed
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0038f';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0038f';

end $$;


/*
 * stats_unprocessed_responses
 */

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0038g', 'juror', 'stats_unprocessed_responses', 'juror_mod', 'stats_unprocessed_responses', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.stats_unprocessed_responses),
		expected_target_count = (select count(1) from juror_digital.stats_unprocessed_responses)
where 	script_number = '0038g';

do $$

begin
	
truncate table juror_dashboard.stats_unprocessed_responses;

with target 
as
(	insert into juror_dashboard.stats_unprocessed_responses(loc_code,unprocessed_count)
	select
		loc_code,
		unprocessed_count
	from
		juror_digital.stats_unprocessed_responses
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0038g';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0038g';

end $$;


/*
 * survey_response
 */

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0038h', 'juror', 'survey_response', 'juror_mod', 'survey_response', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.survey_response),
		expected_target_count = (select count(1) from juror_digital.survey_response)
where 	script_number = '0038h';

do $$

begin
	
truncate table juror_dashboard.survey_response;

with target as (	
	insert into juror_dashboard.survey_response(id,survey_id,user_no,survey_response_date,satisfaction_desc,created)
	select
		id,
		survey_id,
		user_no,
		survey_response_date,
		satisfaction_desc,
		created
	from
		juror_digital.survey_response
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0038h';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0038h';

end $$;


/*
 * stats_welsh_online_responses
 */

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0038i', 'juror', 'stats_welsh_online_responses', 'juror_mod', 'stats_welsh_online_responses', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.stats_welsh_online_responses),
		expected_target_count = (select count(1) from juror_digital.stats_welsh_online_responses)
where 	script_number = '0038i';

do $$

begin
	
truncate table juror_dashboard.stats_welsh_online_responses;

with target as (	
	insert into juror_dashboard.stats_welsh_online_responses(summons_month,welsh_response_count)
	select
		summons_month,
		welsh_response_count
	from
		juror_digital.stats_welsh_online_responses
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0038i';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0038i';

end $$;


-- verify results
select * from juror_mod.migration_log where script_number like '0038%' order by script_number;
select * from juror_dashboard.stats_deferrals limit 10;
select * from juror_dashboard.stats_excusals limit 10;
select * from juror_dashboard.stats_not_responded limit 10;
select * from juror_dashboard.stats_response_times limit 10;
select * from juror_dashboard.stats_thirdparty_online limit 10;
select * from juror_dashboard.stats_auto_processed limit 10;
select * from juror_dashboard.stats_unprocessed_responses limit 10;
select * from juror_dashboard.survey_response limit 10;
select * from juror_dashboard.stats_welsh_online_responses limit 10;