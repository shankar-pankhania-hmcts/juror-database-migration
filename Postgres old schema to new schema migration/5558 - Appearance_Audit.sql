/*
 * Task: 5558 - Develop migration script(s) to migrate the PART_EXPENSES table to the new appearance_audit table
 *
 * 				***********************************************
 * 				*** Run task 5556 first and do not truncate ***
 * 				***********************************************
 */
ALTER TABLE juror_mod.appearance_audit
	DROP CONSTRAINT IF EXISTS fk_revision_number;
ALTER TABLE juror_mod.appearance_audit
	DROP CONSTRAINT IF EXISTS fk_f_audit;


/*
 * migrate part_expenses
 */
WITH rows
AS
(
	INSERT INTO juror_mod.appearance_audit(revision,rev_type,attendance_date,juror_number,loc_code,time_in,time_out,trial_number,non_attendance,no_show,mileage_due,mileage_paid,
		misc_description,pay_cash,last_updated_by,created_by,public_transport_total_due,public_transport_total_paid,hired_vehicle_total_due,hired_vehicle_total_paid,
		motorcycle_total_due,motorcycle_total_paid,car_total_due,car_total_paid,pedal_cycle_total_due,pedal_cycle_total_paid,childcare_total_due,childcare_total_paid,
		parking_total_due,parking_total_paid,misc_total_due,misc_total_paid,smart_card_due,smart_card_paid,travel_time,payment_approved_date,expense_submitted_date,
		is_draft_expense,f_audit,sat_on_jury,pool_number,appearance_stage,loss_of_earnings_due,loss_of_earnings_paid,subsistence_due,subsistence_paid,attendance_type)
	SELECT DISTINCT
		 	NEXTVAL('public.rev_info_seq') as revision,
	 		CASE 
				WHEN RANK() OVER(PARTITION BY pe.part_no,a.loc_code ORDER BY pe.part_no,a.loc_code,pe.att_date asc, pe.number_atts ASC) = 1
					THEN 0 -- first insert
					ELSE 1 -- update
			END as rev_type,
			pe.att_date as attendance_date,
			pe.part_no as juror_number,
			a.loc_code,
			a.timein as time_in,
			a.timeout as time_out,
			CASE 
				WHEN EXISTS(SELECT 1 FROM juror_mod.trial t WHERE t.trial_number = a.pool_trial_no)
					THEN a.pool_trial_no
					ELSE NULL
			END AS trial_number,
			CASE UPPER(a.non_attendance)
				WHEN 'Y'
					THEN true
					ELSE false
			END AS non_attendance,
			CASE 
				WHEN EXISTS(SELECT 1 FROM juror.fta_lett fl WHERE fl.part_no = pe.part_no AND fl.owner = pe.owner AND fl.no_show_date_printed IS NOT NULL)
					THEN true
					ELSE false
			END AS no_show,
			CASE pe.number_atts
				WHEN 1 
					THEN pe.total_mileage
				WHEN 2
					THEN NULL
			END AS mileage_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN pe.total_mileage
			END AS mileage_paid,
			pe.misc_description,
			CASE UPPER(pe.pay_cash)
				WHEN 'Y'
					THEN true
					ELSE false
			END AS pay_cash,
			pe.user_id as last_updated_by,
			pe.user_id as created_by,
			CASE pe.number_atts
				WHEN 1 
					THEN pe.public_trans
				WHEN 2
					THEN NULL
			END AS public_transport_total_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN pe.public_trans
			END AS public_transport_total_paid,
			CASE pe.number_atts
				WHEN 1 
					THEN pe.hired_vehicle_total
				WHEN 2
					THEN NULL
			END AS hired_vehicle_total_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN pe.hired_vehicle_total
			END AS hired_vehicle_total_paid,
			CASE pe.number_atts
				WHEN 1 
					THEN pe.mcycles_total
				WHEN 2
					THEN NULL
			END AS motorcycle_total_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN pe.mcycles_total
			END AS motorcycle_total_paid,
			CASE pe.number_atts
				WHEN 1 
					THEN pe.mcars_total
				WHEN 2
					THEN NULL
			END AS car_total_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN pe.mcars_total
			END AS car_total_paid,
			CASE pe.number_atts
				WHEN 1 
					THEN pe.pcycles_total
				WHEN 2
					THEN NULL
			END AS pedal_cycle_total_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN pe.pcycles_total
			END AS pedal_cycle_total_paid,
			CASE pe.number_atts
				WHEN 1 
					THEN pe.child_care
				WHEN 2
					THEN NULL
			END AS childcare_total_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN pe.child_care
			END AS childcare_total_paid,
			CASE pe.number_atts
				WHEN 1 
					THEN pe.public_parking_total
				WHEN 2
					THEN NULL
			END AS parking_total_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN pe.public_parking_total
			END AS parking_total_paid,
			CASE pe.number_atts
				WHEN 1 
					THEN pe.misc_amount
				WHEN 2
					THEN NULL
			END AS misc_total_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN pe.misc_amount
			END AS misc_total_paid,
			CASE pe.number_atts
				WHEN 1 
					THEN pe.amt_spent
				WHEN 2
					THEN NULL
			END AS smart_card_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN pe.amt_spent
			END AS smart_card_paid,
			pe.travel_time,
			pe.date_aramis_created as payment_approved_date,
			pe.exp_subs_date as expense_submitted_date,
			CASE UPPER(pe.pay_accepted)
				WHEN 'Y'
					THEN false
					ELSE true
			END AS is_draft_expense,
			RIGHT(a.faudit,LENGTH(a.faudit)-1)::BIGINT AS f_audit, -- Remove the leading F character to leave just the digits
			CASE 
				WHEN a.court_emp = 'J'
					THEN true
					ELSE false
			END AS sat_on_jury,
			CASE 
				WHEN LENGTH(a.pool_trial_no) = 9 AND EXISTS(SELECT 1 FROM juror.unique_pool up WHERE up.pool_no = a.pool_trial_no)
					THEN a.pool_trial_no
					ELSE NULL
			END AS pool_number,
			CASE a.app_stage 
				WHEN 1
					THEN 'CHECKED_IN' 
				WHEN 2
					THEN 'CHECKED_OUT' 
				WHEN 4
					THEN 'APPEARANCE_CONFIRMED' 
				WHEN 8
					THEN 'APPEARANCE_CONFIRMED' 
				WHEN 9
					THEN 'EXPENSE_ENTERED' 
				WHEN 10
					THEN 'EXPENSE_AUTHORISED' 
				WHEN 11
					THEN 'EXPENSE_EDITED'
					ELSE 'APPEARANCE_CONFIRMED'
			END AS appearance_stage,
			CASE pe.number_atts
				WHEN 1 
					THEN COALESCE(pe.los_lfour_total,pe.los_mfour_total,pe.loss_mten_total,pe.loss_oten_h_total)
				WHEN 2
					THEN NULL
			END AS loss_of_earnings_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN COALESCE(pe.los_lfour_total,pe.los_mfour_total,pe.loss_mten_total,pe.loss_oten_h_total)
			END AS loss_of_earnings_paid,
			CASE pe.number_atts
				WHEN 1 
					THEN COALESCE(pe.subs_lfive_total,pe.subs_mfive_total,pe.loss_oten_total,pe.loss_overnight_total)
				WHEN 2
					THEN NULL
			END AS subsistence_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL
				WHEN 2
					THEN COALESCE(pe.subs_lfive_total,pe.subs_mfive_total,pe.loss_oten_total,pe.loss_overnight_total)
			END AS subsistence_paid,
			CASE
				WHEN COALESCE(pe.los_mfour_total, pe.subs_mfive_total, pe.loss_overnight_total, 0) > 0
					THEN 'FULL_DAY'
				WHEN COALESCE(pe.los_lfour_total, pe.subs_lfive_total, 0) > 0
					THEN 'HALF_DAY'
				WHEN COALESCE(pe.loss_mten_total, 0) > 0
					THEN 'FULL_DAY_LONG_TRIAL'
				WHEN COALESCE(pe.loss_oten_h_total, 0) > 0
					THEN 'HALF_DAY_LONG_TRIAL'
				WHEN UPPER(pe.non_attendance) = 'Y'
					THEN 'NON_ATTENDANCE'
					ELSE 'ABSENT'
			END AS attendance_type
	FROM juror.part_expenses pe
	JOIN juror.appearances a
	ON pe.part_no = a.part_no
	AND pe.owner = a.owner
	AND pe.att_date = a.att_date

	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* 
 * verify results
 */
select count(*) from juror.part_expenses;
select max(revision) FROM juror_mod.appearance_audit;
select last_value from rev_info_seq;

select * from juror_mod.appearance_audit a limit 10;
