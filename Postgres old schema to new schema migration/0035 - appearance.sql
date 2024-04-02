/*
 * 
 * +---------------+---------------+----------------+---------------+------------------+
 * | Script Number | Source Schema |  Source Table  | Target Schema |   Target Table   |
 * +---------------+---------------+----------------+---------------+------------------+
 * | 0035a         | juror         | part_expenses  | juror_mod     | appearance       |
 * | 0035b         | juror         | appearances    | juror_mod     | appearance       |
 * | 0035c         | juror         | fta_lett       | juror_mod     | appearance       |
 * | 0035d         | juror         | audit_report   | juror_mod     | appearance_audit |
 * | 0035e         | juror         | audit_f_report | juror_mod     | appearance_audit |
 * +---------------+---------------+----------------+---------------+------------------+
 *  
 * part_expenses
 * -------------
 */

delete from juror_mod.migration_log where script_number like '0035%';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0035a', 'juror', 'part_expenses', 'juror_mod', 'appearance', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror.part_expenses),
		expected_target_count = (select count(1) from juror.part_expenses where number_atts = 1)
where 	script_number = '0035a';

do $$

begin

alter table juror_mod.appearance 
	drop constraint if exists app_loc_code_fk;

alter table juror_mod.appearance 
	drop constraint if exists appearance_juror_fk;

alter table juror_mod.appearance 
	drop constraint if exists appearance_pool_fk;

alter table juror_mod.appearance 
	drop constraint if exists appearance_trial_fk;

truncate table juror_mod.appearance;

with appearence as (
	select distinct
			pe.att_date as attendance_date,
			pe.part_no as juror_number,
			a.loc_code,
			a.timein as time_in,
			a.timeout as time_out,
			case 
				when exists(select 1 from juror.trial t where t.trial_no = a.pool_trial_no) 
					then a.pool_trial_no
				else null
			end as trial_number,
			upper(pe.non_attendance) as non_attendance,
			pe.misc_description,
			case pe.number_atts
				when 1 
					then pe.misc_amount
				when 2
					then null
			end as misc_total_due,
			case pe.number_atts
				when 1 
					then null
				when 2
					then pe.misc_amount
			end as misc_total_paid,
			upper(pe.pay_cash) as pay_cash,
			pe.user_id as last_updated_by,
			pe.user_id as created_by,
			case pe.number_atts
				when 1 
					then pe.public_trans
				when 2
					then null
			end as public_transport_total_due,
			case pe.number_atts
				when 1 
					then null
				when 2
					then pe.public_trans
			end as public_transport_total_paid,
			case pe.number_atts
				when 1 
					then pe.hired_vehicle_total
				when 2
					then null
			end as hired_vehicle_total_due,
			case pe.number_atts
				when 1 
					then null
				when 2
					then pe.hired_vehicle_total
			end as hired_vehicle_total_paid,
			case pe.number_atts
				when 1 
					then pe.mcycles_total
				when 2
					then null
			end as motorcycle_total_due,
			case pe.number_atts
				when 1 
					then null
				when 2
					then pe.mcycles_total
			end as motorcycle_total_paid,
			case pe.number_atts
				when 1 
					then pe.mcars_total 
				when 2
					then null
			end as car_total_due,
			case pe.number_atts
				when 1 
					then null
				when 2
					then pe.mcars_total 
			end as car_total_paid,
			case pe.number_atts
				when 1 
					then pe.pcycles_total
				when 2
					then null
			end as pedal_cycle_total_due,
			case pe.number_atts
				when 1 
					then null
				when 2
					then pe.pcycles_total
			end as pedal_cycle_total_paid,
			case pe.number_atts
				when 1 
					then pe.child_care
				when 2
					then null
			end as childcare_total_due,
			case pe.number_atts
				when 1 
					then null
				when 2
					then pe.child_care
			end as childcare_total_paid,
			case pe.number_atts
				when 1 
					then pe.public_parking_total
				when 2
					then null
			end as parking_total_due,
			case pe.number_atts
				when 1 
					then null 
				when 2
					then pe.public_parking_total
			end as parking_total_paid,
			case pe.number_atts
				when 1 
					then pe.amt_spent
				when 2
					then null
			end as smart_card_due,
			case pe.number_atts
				when 1 
					then null 
				when 2
					then pe.amt_spent
			end as smart_card_paid,
			pe.travel_time * '1 hour'::interval as travel_time,
			upper(pe.pay_accepted) as pay_accepted, 
			right(a.faudit,length(a.faudit)-1) as f_audit, -- remove the leading f character to leave just the digits
			case 
				when upper(a.court_emp) = 'J'
					then 'Y'
					else 'N'
			end as sat_on_jury,
			case 
				when length(a.pool_trial_no) = 9 and exists(select 1 from juror.unique_pool up where up.pool_no = a.pool_trial_no)
					then a.pool_trial_no
					else null
			end as pool_number,
			case a.app_stage 
				when 1
					then 'CHECKED_IN' 
				when 2
					then 'CHECKED_OUT' 
				when 4
					then 'EXPENSE_ENTERED' 
				when 8
					then 'EXPENSE_ENTERED' 
				when 9
					then 'EXPENSE_ENTERED' 
				when 10
					then 'EXPENSE_AUTHORISED' 
				when 11
					then 'EXPENSE_EDITED'
					else null
			end as appearance_stage,
			case pe.number_atts
				when 1 
					then coalesce(pe.los_lfour_total,pe.los_mfour_total,pe.loss_mten_total,pe.loss_oten_h_total,0)
				when 2
					then null 
			end as loss_of_earnings_due,
			case pe.number_atts
				when 1 
					then null 
				when 2
					then coalesce(pe.los_lfour_total,pe.los_mfour_total,pe.loss_mten_total,pe.loss_oten_h_total,0)
			end as loss_of_earnings_paid,
			case pe.number_atts
				when 1 
					then coalesce(pe.subs_lfive_total,pe.subs_mfive_total,pe.loss_oten_total,pe.loss_overnight_total,0)
				when 2
					then null 
			end as subsistence_due,
			case pe.number_atts
				when 1 
					then null 
				when 2
					then coalesce(pe.subs_lfive_total,pe.subs_mfive_total,pe.loss_oten_total,pe.loss_overnight_total,0)
			end as subsistence_paid,
			case
				when coalesce(pe.los_mfour_total, pe.subs_mfive_total, pe.loss_overnight_total, 0) > 0
					then 'FULL_DAY'
				when coalesce(pe.los_lfour_total, pe.subs_lfive_total, 0) > 0
					then 'HALF_DAY'
				when coalesce(pe.loss_mten_total, 0) > 0
					then 'FULL_DAY_LONG_TRIAL'
				when coalesce(pe.loss_oten_h_total, 0) > 0
					then 'HALF_DAY_LONG_TRIAL'
				when upper(pe.non_attendance) = 'Y'
					then 'NON_ATTENDANCE'
					else null
			end as attendance_type,
			case
				when pe.rate_mcars = cl.loc_rate_mcars
					then 0
				when pe.rate_mcars = cl.loc_rate_mcars_2
					then 1
				when pe.rate_mcars = cl.loc_rate_mcars_3
					then 2
			end as travel_jurors_taken_by_car,
			case 
				when pe.mcars_total > 0
					then 'Y'
			end as travel_by_car,
			case
				when pe.rate_mcycles = cl.loc_rate_mcycles
					then 0
				when pe.rate_mcycles = cl.loc_rate_mcycles_2
					then 1
			end as travel_jurors_taken_by_motorcycle,
			case 
				when pe.mcycles_total > 0
					then 'Y' 
			end as travel_by_motorcycle,
			case 
				when pe.pcycles_total > 0
					then 'Y' 
			end as travel_by_bicycle,
			pe.mileage as miles_traveled,
			case 
				when coalesce(pe.subs_lfive_total,pe.subs_mfive_total,pe.loss_oten_total,pe.loss_overnight_total,0) = 0
					then 'NONE'
				when coalesce(pe.subs_lfive_total,0) > 0
					then 'LESS_THAN_OR_EQUAL_TO_10_HOURS'
				when coalesce(pe.subs_mfive_total,pe.loss_overnight_total,pe.loss_oten_total,0) > 0 
					then 'MORE_THAN_10_HOURS'
			end as food_and_drink_claim_type
	from 	juror.part_expenses pe
	join 	juror.appearances a
		on 	pe.part_no = a.part_no
			and pe.owner = a.owner
			and pe.att_date = a.att_date
	join 	juror.court_location cl
		on 	a.loc_code = cl.loc_code
),

target as (
	insert into juror_mod.appearance(attendance_date,juror_number,loc_code,time_in,time_out,trial_number,non_attendance,no_show,
		misc_description,misc_total_due,misc_total_paid,pay_cash,last_updated_by,created_by,public_transport_total_due,public_transport_total_paid,
		hired_vehicle_total_due,hired_vehicle_total_paid,motorcycle_total_due,motorcycle_total_paid,car_total_due,car_total_paid,pedal_cycle_total_due,pedal_cycle_total_paid,
		childcare_total_due,childcare_total_paid,parking_total_due,parking_total_paid,loss_of_earnings_due,loss_of_earnings_paid,subsistence_due,subsistence_paid,
		smart_card_due,smart_card_paid,travel_time,is_draft_expense,f_audit,sat_on_jury,pool_number,appearance_stage,attendance_type,
		travel_jurors_taken_by_car,travel_by_car,travel_jurors_taken_by_motorcycle,travel_by_motorcycle,travel_by_bicycle,miles_traveled,food_and_drink_claim_type)
	select  	a.attendance_date,
				a.juror_number,
				a.loc_code,
				max(a.time_in) as time_in,
				max(a.time_out) as time_out,
				max(a.trial_number) as trial_number,
				case max(a.non_attendance)
					when 'Y' then true
					else false
				end as non_attendance,
				false as no_show,
				max(a.misc_description) as misc_description,
				max(a.misc_total_due) as misc_total_due,
				max(a.misc_total_paid) as misc_total_paid,
				case max(a.pay_cash)
					when 'Y' then true
					else false
				end as pay_cash,
				max(a.last_updated_by) as last_updated_by,
				max(a.created_by) as created_by,
				max(a.public_transport_total_due) as public_transport_total_due,
				max(a.public_transport_total_paid) as public_transport_total_paid,
				max(a.hired_vehicle_total_due) as hired_vehicle_total_due,
				max(a.hired_vehicle_total_paid) as hired_vehicle_total_paid,
				max(a.motorcycle_total_due) as motorcycle_total_due,
				max(a.motorcycle_total_paid) as motorcycle_total_paid,
				max(a.car_total_due) as car_total_due,
				max(a.car_total_paid) as car_total_paid,
				max(a.pedal_cycle_total_due) as pedal_cycle_total_due,
				max(a.pedal_cycle_total_paid) as pedal_cycle_total_paid,
				max(a.childcare_total_due) as childcare_total_due,
				max(a.childcare_total_paid) as childcare_total_paid,
				max(a.parking_total_due) as parking_total_due,
				max(a.parking_total_paid) as parking_total_paid,
				max(a.loss_of_earnings_due) as loss_of_earnings_due,
				max(a.loss_of_earnings_paid) as loss_of_earnings_paid,
				max(a.subsistence_due) as subsistence_due,
				max(a.subsistence_paid) as subsistence_paid,
				max(a.smart_card_due) as smart_card_due,
				max(a.smart_card_paid) as smart_card_paid,
				max(a.travel_time) as travel_time,
				case max(a.pay_accepted)
					when 'Y' then false
					else true
				end as is_draft_expense,
				max(a.f_audit::bigint) as f_audit,
				case max(a.sat_on_jury)
					when 'Y' then true
					else false
				end as sat_on_jury,
				max(a.pool_number) as pool_number,
				max(a.appearance_stage) as appearance_stage,
				max(a.attendance_type) as attendance_type,
				max(a.travel_jurors_taken_by_car) as travel_jurors_taken_by_car,
				case max(a.travel_by_car)
					when 'Y' then true
				end as travel_by_car,
				max(a.travel_jurors_taken_by_motorcycle) as travel_jurors_taken_by_motorcycle,
				case max(a.travel_by_motorcycle)
					when 'Y' then true
				end as travel_by_motorcycle,
				case max(a.travel_by_bicycle)
					when 'Y' then true
				end as travel_by_bicycle,
				max(a.miles_traveled) as miles_traveled,
				max(a.food_and_drink_claim_type) as food_and_drink_claim_type
	from 		appearence a
	group by 	a.attendance_date,
			 	a.juror_number,
			 	a.loc_code
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0035a';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0035a';

end $$;


/*******************************************************************************************************
 * Also insert any rows in JUROR.APPEARANCES that do not have an associated row in JUROR.PART_EXPENSES *
 *******************************************************************************************************/

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0035b', 'juror', 'appearances', 'juror_mod', 'appearance', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror.appearances),
		expected_target_count = (select count(1) from juror.appearances a where not exists(select 1 from juror.part_expenses pe where pe.part_no = a.part_no and pe.att_date = a.att_date))
where 	script_number = '0035b';

do $$

begin

with target as (
	insert into juror_mod.appearance(attendance_date,juror_number,loc_code,f_audit,time_in,time_out,trial_number,appearance_stage,non_attendance)
	select distinct 
			a.att_date,
			a.part_no,
			a.loc_code,
			right(a.faudit, length(a.faudit)-1)::bigint as f_audit, -- remove the leading f character to leave just the digits
			a.timein,
			a.timeout,
			case 
				when exists(select 1 from juror.trial t where t.trial_no = a.pool_trial_no)
					then a.pool_trial_no
					else null
			end as trial_number,
			case a.app_stage
				when 1
					then 'CHECKED_IN' 
				when 2
					then 'CHECKED_OUT' 
				when 4
					then 'EXPENSE_ENTERED' 
				when 8
					then 'EXPENSE_ENTERED' 
				when 9
					then 'EXPENSE_ENTERED' 
				when 10
					then 'EXPENSE_AUTHORISED' 
				when 11
					then 'EXPENSE_EDITED'
					else null
			end as appearance_stage,
			case 
				when a.non_attendance = 'Y' then true 
				else false 
			end as non_attendance
	from 	juror.appearances a
	where 	not exists(select 1 from juror.part_expenses pe where pe.part_no = a.part_no and pe.att_date = a.att_date)
	
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0035b';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0035b';

end $$;



/*
 * FTA letters - for each no show record insert a basic entry into appearance
 */
insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0035c', 'juror', 'fta_lett', 'juror_mod', 'appearance', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror.fta_lett where date_fta is not null),
		expected_target_count = (	select 		count(1) 
									from 		juror.fta_lett fl
									join 		juror_mod.juror_pool jp 
										on 		fl.part_no = jp.juror_number
												and fl."owner" = jp."owner"
									where 		fl.date_fta is not null
												and jp.is_active = true
												and not exists(select 1 from juror_mod.appearance a where a.juror_number = fl.part_no and a.attendance_date = fl.date_fta and a.loc_code = left(jp.pool_number,3))
								)
where 	script_number = '0035c';

do $$

begin
	
with target as (
	insert into juror_mod.appearance(attendance_date,juror_number,loc_code,no_show,pool_number,created_by)
	select distinct
			fl.date_fta as attendance_date,
			fl.part_no as juror_number,
			left(jp.pool_number,3) as loc_code,  -- this is nullable in the source table so use parent row from appearance
			true as no_show,
			jp.pool_number,
			'SYSTEM' as created_by
	from 	juror.fta_lett fl 
	join 	juror_mod.juror_pool jp 
		on 	fl.part_no = jp.juror_number
			and fl."owner" = jp."owner"
	where 	fl.date_fta is not null
			and jp.is_active = true
			and not exists(select 1 from juror_mod.appearance a where a.juror_number = fl.part_no and a.attendance_date = fl.date_fta and a.loc_code = left(jp.pool_number,3))
	
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0035c';


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0035c';

end $$;


alter table juror_mod.appearance add constraint app_loc_code_fk 
	foreign key (loc_code) references juror_mod.court_location(loc_code);
alter table juror_mod.appearance add constraint appearance_juror_fk 
	foreign key (juror_number) references juror_mod.juror(juror_number);
alter table juror_mod.appearance add constraint appearance_pool_fk 
	foreign key (pool_number) references juror_mod.pool(pool_no);
alter table juror_mod.appearance add constraint appearance_trial_fk 
	foreign key (trial_number, loc_code) references juror_mod.trial(trial_number, loc_code);



-- verify results
select * from juror_mod.migration_log where script_number like '0035%' order by script_number;
select * from juror_mod.appearance limit 10;
select * from juror_mod.appearance_audit limit 10;
select * from juror_mod.financial_audit_details limit 10;
select * from juror_mod.financial_audit_details_appearances limit 10;