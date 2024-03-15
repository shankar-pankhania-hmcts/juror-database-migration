/*
 * Task: 5557 - Develop migration script(s) to migrate the PART_EXPENSES table to the new appearance table
 *
 * 				Inserts are split into two sections - first based on part_expenses and the second on just appearance
 */
ALTER TABLE juror_mod.appearance DROP CONSTRAINT IF EXISTS app_loc_code_fk;
ALTER TABLE juror_mod.appearance DROP CONSTRAINT IF EXISTS appearance_juror_fk;
ALTER TABLE juror_mod.appearance DROP CONSTRAINT IF EXISTS appearance_pool_fk;
ALTER TABLE juror_mod.appearance DROP CONSTRAINT IF EXISTS appearance_trial_fk;

TRUNCATE TABLE juror_mod.appearance;	-- task 5555 is now merged into the bottom of this script

WITH appearence
AS
(
	SELECT DISTINCT
			pe.att_date as attendance_date,
			pe.part_no as juror_number,
			a.loc_code,
			a.timein as time_in,
			a.timeout as time_out,
			CASE 
				WHEN EXISTS(SELECT 1 FROM juror.trial t WHERE t.trial_no = a.pool_trial_no)
					THEN a.pool_trial_no
					ELSE NULL
			END AS trial_number,
			UPPER(pe.non_attendance) as non_attendance,
			pe.misc_description,
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
			UPPER(pe.pay_cash) as pay_cash,
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
			pe.travel_time*'1 hour'::INTERVAL as travel_time,
			UPPER(pe.pay_accepted) AS pay_accepted, 
			RIGHT(a.faudit,LENGTH(a.faudit)-1) AS f_audit, -- Remove the leading F character to leave just the digits
			CASE 
				WHEN UPPER(a.court_emp) = 'J'
					THEN 'Y'
					ELSE 'N'
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
					ELSE NULL
			END AS appearance_stage,
			CASE pe.number_atts
				WHEN 1 
					THEN COALESCE(pe.los_lfour_total,pe.los_mfour_total,pe.loss_mten_total,pe.loss_oten_h_total,0)
				WHEN 2
					THEN NULL 
			END AS loss_of_earnings_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL 
				WHEN 2
					THEN COALESCE(pe.los_lfour_total,pe.los_mfour_total,pe.loss_mten_total,pe.loss_oten_h_total,0)
			END AS loss_of_earnings_paid,
			CASE pe.number_atts
				WHEN 1 
					THEN COALESCE(pe.subs_lfive_total,pe.subs_mfive_total,pe.loss_oten_total,pe.loss_overnight_total,0)
				WHEN 2
					THEN NULL 
			END AS subsistence_due,
			CASE pe.number_atts
				WHEN 1 
					THEN NULL 
				WHEN 2
					THEN COALESCE(pe.subs_lfive_total,pe.subs_mfive_total,pe.loss_oten_total,pe.loss_overnight_total,0)
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
					ELSE NULL
			END AS attendance_type,
			CASE
				WHEN pe.rate_mcars = cl.loc_rate_mcars
					THEN 0
				WHEN pe.rate_mcars = cl.loc_rate_mcars_2
					THEN 1
				WHEN pe.rate_mcars = cl.loc_rate_mcars_3
					THEN 2
			END AS travel_jurors_taken_by_car,
			CASE 
				WHEN pe.mcars_total > 0
					THEN 'Y'
			END AS travel_by_car,
			CASE
				WHEN pe.rate_mcycles = cl.loc_rate_mcycles
					THEN 0
				WHEN pe.rate_mcycles = cl.loc_rate_mcycles_2
					THEN 1
			END AS travel_jurors_taken_by_motorcycle,
			CASE 
				WHEN pe.mcycles_total > 0
					THEN 'Y' 
			END AS travel_by_motorcycle,
			CASE 
				WHEN pe.pcycles_total > 0
					THEN 'Y' 
			END AS travel_by_bicycle,
			pe.mileage AS miles_traveled,
			CASE 
				WHEN COALESCE(pe.subs_lfive_total,pe.subs_mfive_total,pe.loss_oten_total,pe.loss_overnight_total,0) = 0
					THEN 'NONE'
				WHEN COALESCE(pe.subs_lfive_total,0) > 0
					THEN 'LESS_THAN_1O_HOURS'
				WHEN COALESCE(pe.subs_mfive_total,pe.loss_overnight_total,pe.loss_oten_total,0) > 0 
					THEN 'MORE_THAN_10_HOURS'
			END AS food_and_drink_claim_type
	FROM juror.part_expenses pe
	JOIN juror.appearances a
	ON pe.part_no = a.part_no
	AND pe.owner = a.owner
	AND pe.att_date = a.att_date
	JOIN juror.court_location cl
	ON a.loc_code = cl.loc_code
),
rows
AS
(
	INSERT INTO juror_mod.appearance(attendance_date,juror_number,loc_code,time_in,time_out,trial_number,non_attendance,no_show,
		misc_description,misc_total_due,misc_total_paid,pay_cash,last_updated_by,created_by,public_transport_total_due,public_transport_total_paid,
		hired_vehicle_total_due,hired_vehicle_total_paid,motorcycle_total_due,motorcycle_total_paid,car_total_due,car_total_paid,pedal_cycle_total_due,pedal_cycle_total_paid,
		childcare_total_due,childcare_total_paid,parking_total_due,parking_total_paid,loss_of_earnings_due,loss_of_earnings_paid,subsistence_due,subsistence_paid,
		smart_card_due,smart_card_paid,travel_time,is_draft_expense,f_audit,sat_on_jury,pool_number,appearance_stage,attendance_type,
		travel_jurors_taken_by_car,travel_by_car,travel_jurors_taken_by_motorcycle,travel_by_motorcycle,travel_by_bicycle,miles_traveled,food_and_drink_claim_type)
	SELECT  a.attendance_date,
			a.juror_number,
			a.loc_code,
			MAX(a.time_in) as time_in,
			MAX(a.time_out) as time_out,
			MAX(a.trial_number) as trial_number,
			CASE MAX(a.non_attendance)
				WHEN 'Y'
					THEN true
					ELSE false
			END AS non_attendance,
			false AS no_show,
			MAX(a.misc_description) as misc_description,
			MAX(a.misc_total_due) as misc_total_due,
			MAX(a.misc_total_paid) as misc_total_paid,
			CASE MAX(a.pay_cash)
				WHEN 'Y'
					THEN true
					ELSE false
			END AS pay_cash,
			MAX(a.last_updated_by) as last_updated_by,
			MAX(a.created_by) as created_by,
			MAX(a.public_transport_total_due) as public_transport_total_due,
			MAX(a.public_transport_total_paid) as public_transport_total_paid,
			MAX(a.hired_vehicle_total_due) as hired_vehicle_total_due,
			MAX(a.hired_vehicle_total_paid) as hired_vehicle_total_paid,
			MAX(a.motorcycle_total_due) as motorcycle_total_due,
			MAX(a.motorcycle_total_paid) as motorcycle_total_paid,
			MAX(a.car_total_due) as car_total_due,
			MAX(a.car_total_paid) as car_total_paid,
			MAX(a.pedal_cycle_total_due) as pedal_cycle_total_due,
			MAX(a.pedal_cycle_total_paid) as pedal_cycle_total_paid,
			MAX(a.childcare_total_due) as childcare_total_due,
			MAX(a.childcare_total_paid) as childcare_total_paid,
			MAX(a.parking_total_due) as parking_total_due,
			MAX(a.parking_total_paid) as parking_total_paid,
			MAX(a.loss_of_earnings_due) as loss_of_earnings_due,
			MAX(a.loss_of_earnings_paid) as loss_of_earnings_paid,
			MAX(a.subsistence_due) as subsistence_due,
			MAX(a.subsistence_paid) as subsistence_paid,
			MAX(a.smart_card_due) as smart_card_due,
			MAX(a.smart_card_paid) as smart_card_paid,
			MAX(a.travel_time) as travel_time,
			CASE MAX(a.pay_accepted)
				WHEN 'Y'
					THEN false
					ELSE true
			END AS is_draft_expense,
			MAX(a.f_audit::BIGINT) AS f_audit,
			CASE MAX(a.sat_on_jury)
				WHEN 'Y'
					THEN true
					ELSE false
			END AS sat_on_jury,
			MAX(a.pool_number) as pool_number,
			MAX(a.appearance_stage) as appearance_stage,
			MAX(a.attendance_type) as attendance_type,
			MAX(a.travel_jurors_taken_by_car) as travel_jurors_taken_by_car,
			CASE MAX(a.travel_by_car)
				WHEN 'Y'
					THEN true
			END AS travel_by_car,
			MAX(a.travel_jurors_taken_by_motorcycle) as travel_jurors_taken_by_motorcycle,
			CASE MAX(a.travel_by_motorcycle)
				WHEN 'Y'
					THEN true
			END AS travel_by_motorcycle,
			CASE MAX(a.travel_by_bicycle)
				WHEN 'Y'
					THEN true
			END AS travel_by_bicycle,
			MAX(a.miles_traveled) as miles_traveled,
			MAX(a.food_and_drink_claim_type) as food_and_drink_claim_type
	FROM appearence a
	GROUP BY a.attendance_date,
			 a.juror_number,
			 a.loc_code

	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* 
 * verify results
 */
select count(*)
from (
		select  a.att_date,
				a.part_no,
				a.loc_code
		from juror.part_expenses pe
		join juror.appearances a on a.part_no = pe.part_no and a.owner = pe.owner and a.att_date = pe.att_date 
		group by a.att_date,
				a.part_no,
				a.loc_code
	 ) as part_expenses;


/*****************************************************************************************
 * Also insert any rows in Appearances that do not have an associated row in Part_Expenses
 *****************************************************************************************/	
WITH rows
AS
(
	INSERT INTO juror_mod.appearance(attendance_date,juror_number,loc_code,f_audit,time_in,time_out,trial_number,appearance_stage,non_attendance)
	SELECT DISTINCT 
			a.att_date,
			a.part_no,
			a.loc_code,
			RIGHT(a.faudit,LENGTH(a.faudit)-1)::bigint AS f_audit, -- Remove the leading F character to leave just the digits
			a.timein,
			a.timeout,
			CASE 
				WHEN EXISTS(SELECT 1 FROM juror.trial t WHERE t.trial_no = a.pool_trial_no)
					THEN a.pool_trial_no
					ELSE NULL
			END AS trial_number,
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
					ELSE NULL
			END AS appearance_stage,
			CASE 
				WHEN a.non_attendance = 'Y'
					THEN true 
					ELSE false 
			END AS non_attendance
	FROM juror.appearances a
	WHERE NOT EXISTS(SELECT 1 FROM juror.part_expenses pe WHERE pe.part_no = a.part_no AND pe.att_date = a.att_date)
	
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* 
 * verify results
 */
select count(*) from juror.appearances a WHERE NOT EXISTS(SELECT 1 FROM juror.part_expenses pe WHERE pe.part_no = a.part_no AND pe.att_date = a.att_date);


/*
 * FTA LETTERS - for each no show record insert a basic entry into appearance
 */
WITH rows
AS
(
	INSERT INTO juror_mod.appearance(attendance_date,juror_number,loc_code,no_show,pool_number,created_by)
	SELECT DISTINCT
			fl.date_fta as attendance_date,
			fl.part_no as juror_number,
			LEFT(jp.pool_number,3) as loc_code,  -- this is nullable in the source table so use parent row from appearance
			true AS no_show,
			jp.pool_number,
			'SYSTEM' as created_by
	FROM juror.fta_lett fl 
	JOIN juror_mod.juror_pool jp 
	ON fl.part_no = jp.juror_number
	AND fl.owner = jp.owner
	WHERE fl.date_fta IS NOT NULL
	AND jp.is_active = true
	AND NOT EXISTS(SELECT 1 FROM juror_mod.appearance a WHERE a.juror_number = fl.part_no AND a.attendance_date = fl.date_fta and a.loc_code = LEFT(jp.pool_number,3))
	
	RETURNING 1
)
SELECT COUNT(*) FROM rows;


ALTER TABLE juror_mod.appearance ADD CONSTRAINT app_loc_code_fk FOREIGN KEY (loc_code) REFERENCES juror_mod.court_location(loc_code) NOT VALID;
ALTER TABLE juror_mod.appearance ADD CONSTRAINT appearance_juror_fk FOREIGN KEY (juror_number) REFERENCES juror_mod.juror(juror_number) NOT VALID;
ALTER TABLE juror_mod.appearance ADD CONSTRAINT appearance_pool_fk FOREIGN KEY (pool_number) REFERENCES juror_mod.pool(pool_no) NOT VALID;
ALTER TABLE juror_mod.appearance ADD CONSTRAINT appearance_trial_fk FOREIGN KEY (trial_number, loc_code) REFERENCES juror_mod.trial(trial_number, loc_code) NOT VALID;

/* 
 * verify results
 */
select count(*) 
FROM juror.fta_lett fl 
JOIN juror_mod.juror_pool jp 
ON fl.part_no = jp.juror_number
AND fl.owner = jp.owner
WHERE fl.date_fta IS NOT NULL
AND jp.is_active = true;

select * from juror_mod.appearance a limit 10;
