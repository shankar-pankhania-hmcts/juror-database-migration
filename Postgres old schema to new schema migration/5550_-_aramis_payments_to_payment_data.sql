/*
 * Task 5550: Develop migration script(s) for migrating the ARAMIS_PAYMENTS table to the new payment_data table
 *
 */

TRUNCATE TABLE juror_mod.payment_data;

WITH rows
AS
(
	INSERT INTO juror_mod.payment_data(loc_code,unique_id,creation_date,expense_total,juror_number,invoice_id,bank_sort_code,bank_ac_name,bank_ac_number,build_soc_number,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode,auth_code,juror_name,loc_cost_centre,travel_total,subsistence_total,financial_loss_total,expense_file_name,extracted)
	SELECT  ap.loc_code,
			ap.unique_id,
			ap.creation_date,
			ap.expense_total,
			LEFT(ap.part_invoice,9) as juror_number,
			RIGHT(ap.part_invoice,7) as invoice_id,
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
			ap.name as juror_name,
			ap.loc_cost_centre,
			ap.travel_total,
			ap.sub_total as subsistence_total,
			ap.floss_total asfinancial_loss_total,
			ap.con_file_ref as expense_file_name,
			CASE 
				WHEN ap.con_file_ref IS NOT NULL
					THEN true
					ELSE false
			END as extracted
	FROM juror.aramis_payments ap
	
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/*
 * Verify results
 */
select count(*) from juror.aramis_payments;
select * from juror_mod.payment_data limit 10;
