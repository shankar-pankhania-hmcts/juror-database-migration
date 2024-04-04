/*
 *
 * +---------------+---------------+-----------------+---------------+--------------+
 * | Script Number | Source Schema |  Source Table   | Target Schema | Target Table |
 * +---------------+---------------+-----------------+---------------+--------------+
 * |          0036 | juror         | aramis_payments | juror_mod     | payment_data |
 * +---------------+---------------+-----------------+---------------+--------------+
 * 
 * payment_data
 * ------------
 */

delete from juror_mod.migration_log where script_number = '0036';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0036', 'juror', 'aramis_payments', 'juror_mod', 'payment_data', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror.aramis_payments),
		expected_target_count = (select count(1) from juror.aramis_payments)
where 	script_number = '0036';

do $$

begin

truncate table juror_mod.payment_data;

with target as (
	insert into juror_mod.payment_data(loc_code,unique_id,creation_date,expense_total,juror_number,invoice_id,bank_sort_code,bank_ac_name,bank_ac_number,build_soc_number,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode,auth_code,juror_name,loc_cost_centre,travel_total,subsistence_total,financial_loss_total,expense_file_name,extracted)
	select  ap.loc_code,
			ap.unique_id,
			ap.creation_date,
			ap.expense_total,
			left(ap.part_invoice,9) as juror_number,
			right(ap.part_invoice,7) as invoice_id,
			ap.bank_sort_code,
			ap.bank_ac_name,
			ap.bank_ac_number,
			ap.build_soc_number,
			ap.address_line1,
			ap.address_line2,
			ap.address_line3,
			ap.address_line4,
			ap.address_line5,
			ap.postcode,
			ap.aramis_auth_code,
			ap."name" as juror_name,
			ap.loc_cost_centre,
			ap.travel_total,
			ap.sub_total as subsistence_total,
			ap.floss_total asfinancial_loss_total,
			ap.con_file_ref as expense_file_name,
			case 
				when ap.con_file_ref is not null
					then true
					else false
			end as extracted
	from juror.aramis_payments ap
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0036';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0036';

end $$;


-- verify results
select * from juror_mod.migration_log where script_number = '0036';
select * from juror_mod.payment_data limit 10;