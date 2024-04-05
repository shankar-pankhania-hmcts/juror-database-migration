/*
 *
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0033 | juror         | messages     | juror_mod     | message      |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * messages
 * --------
 */

delete from juror_mod.migration_log where script_number = '0033';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0033', 'juror', 'messages', 'juror_mod', 'message', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.messages),
		expected_target_count = (select count(1) from juror.messages)
where 	script_number = '0033';

do $$

begin
	
-- drop primary key constraint

alter table juror_mod.message drop constraint if exists message_pkey;

truncate table juror_mod.message;

with target as (
	insert into juror_mod.message(juror_number,file_datetime,username,loc_code,phone,email,pool_no,subject,message_text,message_id,message_read)
	select distinct 
			m.part_no,
			to_timestamp(m.file_datetime, 'YYYYMMDD_HH24MIss')::timestamp as file_datetime,
			m.username,
			m.loc_code,
			m.phone,
			m.email,
			m.pool_no,
			m.subject,
			m.message_text,
			m.message_id,
			m.message_read
	from juror.messages m
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0033';

alter table juror_mod.message add constraint message_pkey 
	primary key (juror_number, file_datetime, username, loc_code);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0033';
	
end $$;
	
-- verify results
select * from juror_mod.migration_log where script_number = '0033';
select * from juror_mod.message limit 10;