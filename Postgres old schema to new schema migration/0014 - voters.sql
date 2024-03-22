/*
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0014 | juror         | voters<nnn>  | juror_mod     | voters       |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * voters
 * ------
 * 
 */

delete from juror_mod.migration_log where script_number = '0014';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0014', 'juror', 'voters<nnn>', 'juror_mod', 'voters');


with tbl as (
	select	table_schema,
          	table_name
   	from 	information_schema."tables"
   	where 	table_name like 'voters%'
     		and table_schema in ('juror'))
, tbl_count as (
	select	table_schema,
       		table_name,
       		(xpath('/row/c/text()', query_to_xml(format('select count(*) as c from %I.%I', table_schema, table_name), false, true, '')))[1]::text::int as rows_n
	from	tbl)

update	juror_mod.migration_log
set		source_count = (select sum(rows_n) from tbl_count),
		expected_target_count = (select sum(rows_n) from tbl_count)
where 	script_number = '0014';

do $$

declare

	tmp_row record;

begin

truncate table juror_mod.voters;


for tmp_row in (
	select	table_name
   	from 	information_schema."tables"
   	where 	table_name like 'voters%'
     		and table_schema in ('juror')) 
loop
	
	execute format('insert into juror_mod.voters(loc_code, part_no, register_lett, poll_number, new_marker, title, lname, fname, dob, flags, address, address2, address3, address4, address5, address6, zip, date_selected1, date_selected2, date_selected3, rec_num, perm_disqual, source_id) 
	select		%L as loc_code,
				part_no,
				register_lett,
				poll_number,
				new_marker,
				title,
				lname,
				fname,
				dob,
				flags,
				address,
				address2,
				address3,
				address4,
				address5,
				address6,
				zip,
				date_selected1,
				date_selected2,
				date_selected3,
				rec_num,
				perm_disqual,
				source_id
	from		juror.%I', substring(tmp_row.table_name, 7, 3), tmp_row.table_name);
	
end loop;

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from juror_mod.voters),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0014';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0014';
	
end $$;

select * from juror_mod.migration_log where script_number = '0014';
select * from juror_mod.voters limit 10;