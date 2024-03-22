/*
 * +---------------+---------------+---------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table  | Target Schema | Target Table |
 * +---------------+---------------+---------------+---------------+--------------+
 * |          0012 | juror_digital | expenses_rates| juror_mod     | expense_rate |
 * +---------------+---------------+---------------+---------------+--------------+
 * 
 * expense_rate
 * ------------
 * 
 */

delete from juror_mod.migration_log where script_number = '0012';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0012', 'juror_digital', 'expense_rates', 'juror_mod', 'expense_rate');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror_digital.expenses_rates),
		expected_target_count = (select count(1) from juror_digital.expenses_rates)
where 	script_number = '0012';

do $$

begin

truncate table juror_mod.expense_rate;

with target
as
(
	insert into juror_mod.expense_rate(expense_type, rate)
	select distinct 
			er.expense_type,
			er.rate
	from juror_digital.expenses_rates er
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0012';

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0012';
end $$;

select * from juror_mod.migration_log where script_number = '0012';
select * from juror_mod.expense_rate limit 10;