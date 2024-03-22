/*
 * 
 * +---------------+---------------+----------------+---------------+------------------------+
 * | Script Number | Source Schema |  Source Table  | Target Schema |      Target Table      |
 * +---------------+---------------+----------------+---------------+------------------------+
 * |          0009 | juror         | manuals_status | juror_mod     | t_pending_juror_status |
 * +---------------+---------------+----------------+---------------+------------------------+
 * 
 * t_pending_juror_status
 * ----------------------
 * 
 */

delete from juror_mod.migration_log where script_number = '0009';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0009', 'juror', 'manuals_status', 'juror_mod', 't_pending_juror_status');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.manuals_status),
		expected_target_count = (select count(1) from juror.manuals_status)
where 	script_number = '0009';

do $$

begin

alter table juror_mod.pending_juror 
	drop constraint if exists pending_juror_status_fk;

truncate table juror_mod.t_pending_juror_status;

with target
as
(
	insert into juror_mod.t_pending_juror_status(code,description)
	select 	ms.code,
			ms.description
	from juror.manuals_status ms
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(*) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0009';


alter table juror_mod.pending_juror 
	add constraint pending_juror_status_fk foreign key (status) references juror_mod.t_pending_juror_status(code) not valid;

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0009';
end $$;



-- verify results
select * from juror_mod.migration_log where script_number = '0009';
select * from juror_mod.t_pending_juror_status limit 10;
