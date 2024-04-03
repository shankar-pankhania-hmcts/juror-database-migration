/*
 * 
 * +---------------+---------------+---------------+---------------+---------------+
 * | Script Number | Source Schema | Source Table  | Target Schema | Target Table  |
 * +---------------+---------------+---------------+---------------+---------------+
 * |          0021 | juror         | content_store | juror_mod     | content_store |
 * +---------------+---------------+---------------+---------------+---------------+
 * 
 * content_store
 * --------------
 */

delete from juror_mod.migration_log where script_number = '0021';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0021', 'juror', 'content_store', 'juror_mod', 'content_store', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.content_store),
		expected_target_count = (select count(1) from juror.content_store)
where 	script_number = '0021';

do $$

begin

truncate table juror_mod.content_store restart identity cascade;

with target as
(
	insert into juror_mod.content_store(request_id,document_id,date_on_q_for_send,file_type,date_sent,"data")
	select  cs.request_id,
			cs.document_id,
			cs.date_on_q_for_send,
			cs.file_type,
			cs.date_sent,
			cs."data"
	from juror.content_store cs
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0021';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0021';
	
end $$; 

-- verify results
select * from juror_mod.migration_log where script_number = '0021';
select * from juror_mod.content_store limit 10;