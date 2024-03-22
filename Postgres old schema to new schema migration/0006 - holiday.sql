/*
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0006 | juror         | holidays     | juror_mod     | holiday      |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * holiday
 * -------
 * 
 */


delete from juror_mod.migration_log where script_number = '0006';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0006', 'juror', 'holidays', 'juror_mod', 'holiday');

do $$

begin


-- build a list of public bank holiday for the next 2 years in order to set the flag true
create temporary table if not exists temp_bankholidays (bank_holiday date, description varchar(30));

--upcoming bank holidays in england and wales 2024
insert into temp_bankholidays (bank_holiday,description) values ('2024/01/01', 'New Year’s Day');
insert into temp_bankholidays (bank_holiday,description) values ('2024/03/29', 'Good Friday');
insert into temp_bankholidays (bank_holiday,description) values ('2024/04/01', 'Easter Monday');
insert into temp_bankholidays (bank_holiday,description) values ('2024/05/06', 'Early May Bank Holiday');
insert into temp_bankholidays (bank_holiday,description) values ('2024/05/27', 'Spring Bank Holiday');
insert into temp_bankholidays (bank_holiday,description) values ('2024/08/26', 'Summer Bank Holiday');
insert into temp_bankholidays (bank_holiday,description) values ('2024/12/25', 'Christmas Day');
insert into temp_bankholidays (bank_holiday,description) values ('2024/12/26', 'Boxing Day');

--upcoming bank holidays in england and wales 2025
insert into temp_bankholidays (bank_holiday,description) values ('2025/01/01', 'New Year’s Day');
insert into temp_bankholidays (bank_holiday,description) values ('2025/04/18', 'Good Friday');
insert into temp_bankholidays (bank_holiday,description) values ('2025/04/21', 'Easter Monday');
insert into temp_bankholidays (bank_holiday,description) values ('2025/05/05', 'Early May Bank Holiday');
insert into temp_bankholidays (bank_holiday,description) values ('2025/05/26', 'Spring Bank Holiday');
insert into temp_bankholidays (bank_holiday,description) values ('2025/08/25', 'Summer Bank Holiday');
insert into temp_bankholidays (bank_holiday,description) values ('2025/12/25', 'Christmas Day');
insert into temp_bankholidays (bank_holiday,description) values ('2025/12/26', 'Boxing Day');


-- update migration log with source record count and expected record count
update	juror_mod.migration_log
set		source_count = (select count(1) from juror.holidays),
		expected_target_count = (select count(1) from temp_bankholidays) + 
		(select count(1) from (select holiday from juror.holidays except select bank_holiday from temp_bankholidays))
where 	script_number = '0006';


truncate juror_mod.holiday restart identity cascade;

with target as 
(
	insert into juror_mod.holiday(owner,holiday,description,public)	
	select  null as owner, 
			tbh.bank_holiday, 
			tbh.description,
			true as public
	from temp_bankholidays tbh
	union
	select distinct 
			h.owner, 
			h.holiday, 
			h.description,
			false
	from juror.holidays h
	where not exists(select 1 from temp_bankholidays tbh where tbh.bank_holiday = h.holiday)
	order by bank_holiday 
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(*) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0006';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0006';


end $$;

-- remove the temporary table
drop table if exists temp_bankholidays;

-- verify results
select * from juror_mod.migration_log where script_number = '0006';
select * from juror_mod.holiday;
