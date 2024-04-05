/*
 * 
 * +---------------+---------------+-----------------------+---------------+---------------+
 * | Script Number | Source Schema | Source Table          | Target Schema | Target Table  |
 * +---------------+---------------+-----------------------+---------------+---------------+
 * | 0028a         | juror         | part_hist             | juror_mod     | juror_history |
 * | 0028b         | juror         | def_lett              | juror_mod     | juror_history |
 * | 0028c         | juror         | def_denied            | juror_mod     | juror_history |
 * | 0028d         | juror         | disq_lett             | juror_mod     | juror_history |
 * | 0028e         | juror         | exc_lett              | juror_mod     | juror_history |
 * | 0028f         | juror         | exc_denied            | juror_mod     | juror_history |
 * | 0028g         | juror         | postpone_lett         | juror_mod     | juror_history |
 * | 0028h         | juror         | fta_lett (show cause) | juror_mod     | juror_history |
 * | 0028i         | juror         | fta_lett (no-show)    | juror_mod     | juror_history |
 * +---------------+---------------+-----------------------+---------------+---------------+
 * 
 * juror_history
 * -------------
 */

delete from juror_mod.migration_log where script_number like '0028%';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0028a', 'juror', 'part_hist', 'juror_mod', 'juror_history', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.part_hist),
		expected_target_count = (select count(1) from (
				select distinct 
						ph.part_no,
						ph.date_part,
						ph.history_code,
						ph.user_id,
						ph.other_information,
						ph.pool_no
				from juror.part_hist ph))
where 	script_number = '0028a';

do $$

begin
	
-- drop indexes to improve performance

drop index if exists juror_mod.juror_history_juror_number_idx;

-- drop foreign key constraints

alter table juror_mod.juror_history 
	drop constraint juror_history_fk;

-- begin data migration

truncate juror_mod.juror_history restart identity cascade;

with target as (
	insert into juror_mod.juror_history(juror_number,date_created,history_code,user_id,other_information,pool_number)
	select distinct 
			ph.part_no,
			ph."date_part",
			ph.history_code,
			ph.user_id,
			ph.other_information,
			ph.pool_no
	from juror.part_hist ph	
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0028a';


alter table juror_mod.juror_history 
	add constraint juror_history_fk foreign key (juror_number) references juror_mod.juror(juror_number) not valid;

create index juror_history_juror_number_idx on juror_mod.juror_history 
	using btree (juror_number, date_created);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0028a';
	
end $$;

-- def_lett updates

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0028b', 'juror', 'def_lett', 'juror_mod', 'juror_history', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.def_lett),
		expected_target_count = (select count(1) from juror.def_lett 
									where date_printed is not null and "owner" != '400')
where 	script_number = '0028b';

do $$

begin
	
with target as (
	update 	juror_mod.juror_history
	set 	other_info_date = l.other_information_date,
			other_info_reference = l.other_information_reference
	from (
			select  dl.part_no,
					dl.date_def::date as other_information_date,
					dl.exc_code as other_information_reference,
					dl.date_printed
			from 	juror.def_lett dl
			where 	dl.date_printed is not null
					and dl."owner" != '400'
		) as l
	where 	juror_mod.juror_history.juror_number = l.part_no
			and juror_mod.juror_history.date_created::date = l.date_printed
			and juror_mod.juror_history.history_code = 'RDEF'
			and juror_mod.juror_history.other_information = 'Deferred Letter'
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0028b';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0028b';
	
end $$;

-- def_denied updates

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0028c', 'juror', 'def_denied', 'juror_mod', 'juror_history', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.def_denied),
		expected_target_count = (select count(1) from juror.def_denied 
									where date_printed is not null and "owner" != '400')
where 	script_number = '0028c';

do $$

begin
	
with target as (
	update	juror_mod.juror_history
	set 	other_info_date = l.other_information_date,
			other_info_reference = l.other_information_reference
	from (
			select  dd.part_no,
					dd.date_def::date as other_information_date,
					dd.exc_code as other_information_reference,
					dd.date_printed
			from 	juror.def_denied dd
			where 	dd.date_printed is not null
					and dd."owner" != '400'
	) as l
	where 	juror_mod.juror_history.juror_number = l.part_no
			and juror_mod.juror_history.date_created::date = l.date_printed
			and juror_mod.juror_history.history_code = 'RDDL'
			and juror_mod.juror_history.other_information = 'Deferred Denied Letter'
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0028c';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0028c';
	
end $$;

-- disq_lett updates

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0028d', 'juror', 'disq_lett', 'juror_mod', 'juror_history', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.disq_lett),
		expected_target_count = (select count(1) from juror.disq_lett 
									where date_printed is not null and "owner" != '400')
where 	script_number = '0028d';

do $$

begin
	
with target as (
	update	juror_mod.juror_history
	set 	other_info_date = l.other_information_date,
			other_info_reference = l.other_information_reference
	from (
			select  dl.part_no,
					dl.date_disq::date as other_information_date,
					dl.disq_code as other_information_reference,
					dl.date_printed
			from 	juror.disq_lett dl
			where 	dl.date_printed is not null
					and dl."owner" != '400'
	) as l
	where 	juror_mod.juror_history.juror_number = l.part_no
			and juror_mod.juror_history.date_created::date = l.date_printed
			and juror_mod.juror_history.history_code = 'RDIS'
			and juror_mod.juror_history.other_information like 'Disqualify Letter%'
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0028d';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0028d';
	
end $$;

-- exc_lett updates

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0028e', 'juror', 'exc_lett', 'juror_mod', 'juror_history', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.exc_lett),
		expected_target_count = (select count(1) from juror.exc_lett 
									where date_printed is not null and "owner" != '400')
where 	script_number = '0028e';

do $$

begin
	
with target as (
	update 	juror_mod.juror_history
	set 	other_info_date = l.other_information_date,
			other_info_reference = l.other_information_reference
	from (
			select  el.part_no,
					el.date_excused::date as other_information_date,
					el.exc_code as other_information_reference,
					el.date_printed
			from 	juror.exc_lett el
			where 	el.date_printed is not null
					and el."owner" != '400'
	) as l
	where 	juror_mod.juror_history.juror_number = l.part_no
			and juror_mod.juror_history.date_created::date = l.date_printed
			and juror_mod.juror_history.history_code = 'REXC'
			and juror_mod.juror_history.other_information = 'Excused Letter'
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0028e';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0028e';
	
end $$;

-- exc_denied_lett updates

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0028f', 'juror', 'exc_denied_lett', 'juror_mod', 'juror_history', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.exc_denied_lett),
		expected_target_count = (select count(1) from juror.exc_denied_lett 
									where date_printed is not null and "owner" != '400')
where 	script_number = '0028f';

do $$

begin
	
with target as (
	update 	juror_mod.juror_history
	set 	other_info_date = l.other_information_date,
			other_info_reference = l.other_information_reference
	from (
			select  edl.part_no,
					edl.date_excused::date as other_information_date,
					edl.exc_code as other_information_reference,
					edl.date_printed
			from 	juror.exc_denied_lett edl
			where 	edl.date_printed is not null
					and edl."owner" != '400'
	) as l
	where 	juror_mod.juror_history.juror_number = l.part_no
			and juror_mod.juror_history.date_created::date = l.date_printed
			and juror_mod.juror_history.history_code = 'REDL'
			and juror_mod.juror_history.other_information = 'Excused Denied Letter'
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0028f';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0028f';
	
end $$;

-- postpone_lett updates

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0028g', 'juror', 'postpone_lett', 'juror_mod', 'juror_history', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.postpone_lett),
		expected_target_count = (select count(1) from juror.postpone_lett 
									where date_printed is not null and "owner" != '400')
where 	script_number = '0028g';

do $$

begin
	
with target as (
	update	juror_mod.juror_history
	set 	other_info_date = l.other_information_date
	from (
			select  pl.part_no,
					pl.date_postpone::date as other_information_date,
					pl.date_printed
			from 	juror.postpone_lett pl
			where 	pl.date_printed is not null
					and pl."owner" != '400'
	) as l
	where 	juror_mod.juror_history.juror_number = l.part_no
			and juror_mod.juror_history.date_created::date = l.date_printed
			and juror_mod.juror_history.history_code = 'RPST'
			and juror_mod.juror_history.other_information = 'Postpone Letter'
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0028g';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0028g';
	
end $$;
	

-- fta_lett updates (show cause letter)

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0028h', 'juror', 'fta_lett_show_cause', 'juror_mod', 'juror_history', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.fta_lett),
		expected_target_count = (select count(1) from juror.fta_lett 
									where date_printed is not null and "owner" != '400')
where 	script_number = '0028h';

do $$

begin
	
with target as (
	update 	juror_mod.juror_history
	set 	other_info_date = l.other_information_date
	from (
			select  fl.part_no,
					fl.date_fta::date as other_information_date,
					fl.date_printed
			from 	juror.fta_lett fl
			where 	fl.date_printed is not null
					and fl."owner" != '400'
	) as l
	where 	juror_mod.juror_history.juror_number = l.part_no
			and juror_mod.juror_history.date_created::date = l.date_printed
			and juror_mod.juror_history.history_code = 'RFTA'
			and juror_mod.juror_history.other_information = 'Show Cause Letter'
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0028h';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0028h';
	
end $$;
	

-- fta_lett updates (no-show letter)

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0028i', 'juror', 'fta_lett_no-show', 'juror_mod', 'juror_history', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.fta_lett),
		expected_target_count = (select count(1) from juror.fta_lett 
									where no_show_date_printed is not null and "owner" != '400')
where 	script_number = '0028i';

do $$

begin
	
with target as (
	update 	juror_mod.juror_history
	set 	other_info_date = l.other_information_date
	from (
			select  fl.part_no,
					fl.date_fta::date as other_information_date,
					fl.no_show_date_printed
			from 	juror.fta_lett fl
			where 	fl.no_show_date_printed is not null
					and fl."owner" != '400'
	) as l
	where 	juror_mod.juror_history.juror_number = l.part_no
			and juror_mod.juror_history.date_created::date = l.date_printed
			and juror_mod.juror_history.history_code = 'RFTA'
			and juror_mod.juror_history.other_information = 'NO-SHOW Letter'
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0028i';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0028i';
	
end $$;
	
-- verify results
select * from juror_mod.migration_log where script_number like '0028%' order by script_number;
select * from juror_mod.juror_history limit 10;
select * from juror_mod.juror_history where history_code = 'RDEF' limit 10;
select * from juror_mod.juror_history where history_code = 'RDDL' limit 10;
select * from juror_mod.juror_history where history_code = 'RDIS' limit 10;
select * from juror_mod.juror_history where history_code = 'REXC' limit 10;
select * from juror_mod.juror_history where history_code = 'REDL' limit 10;
select * from juror_mod.juror_history where history_code = 'RPST' limit 10;
select * from juror_mod.juror_history where history_code = 'RFTA' limit 10;