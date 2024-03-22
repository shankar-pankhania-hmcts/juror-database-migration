/*
 * +---------------+---------------+----------------+---------------+----------------+
 * | Script Number | Source Schema |  Source Table  | Target Schema |  Target Table  |
 * +---------------+---------------+----------------+---------------+----------------+
 * |          0002 | juror         | court_location | juror_mod     | court_location |
 * +---------------+---------------+----------------+---------------+----------------+
 * 
 * court_location
 * ---------------
 */

delete from juror_mod.migration_log where script_number = '0002a';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0002a', 'juror_digital', 'court_location', 'juror_mod', 'court_location');


with "source" as (
	select 	count(cl.loc_code) as source_count
	from juror.court_location cl
)

update	juror_mod.migration_log
set		source_count = (select source_count from "source"),
		expected_target_count = (select source_count from "source")
where 	script_number = '0002a';

do $$

begin

alter table juror_mod.appearance drop constraint if exists app_loc_code_fk;
alter table juror_mod.court_catchment_area drop constraint if exists court_catchment_area_fk_loc_code;
alter table juror_mod.welsh_court_location drop constraint if exists welsh_court_loc_code_fk;
alter table juror_mod.holiday drop constraint if exists holiday_loc_code_fk;
alter table juror_mod.coroner_pool drop constraint if exists coroner_pool_loc_code_fk;
alter table juror_mod.trial drop constraint if exists trial_court_loc_fk;
alter table juror_mod.pool drop constraint if exists pool_loc_code_fk;
alter table juror_mod.utilisation_stats drop constraint if exists utilisation_stats_fk;

truncate table juror_mod.court_location;

with target as (
	insert into juror_mod.court_location("owner",loc_code,loc_name,loc_court_name,loc_attend_time,loc_address1,loc_address2,loc_address3,loc_address4,loc_address5,loc_address6,loc_zip,loc_phone,jury_officer_phone,location_address,region_id,yield,voters_lock,term_of_service,tdd_phone,loc_signature,rate_per_mile_car_0_passengers,rate_per_mile_car_1_passengers,rate_per_mile_car_2_or_more_passengers,rate_per_mile_motorcycle_0_passengers,rate_per_mile_motorcycle_1_or_more_passengers,rate_per_mile_bike,limit_financial_loss_half_day,limit_financial_loss_full_day,limit_financial_loss_half_day_long_trial,limit_financial_loss_full_day_long_trial,public_transport_soft_limit,rate_substance_standard,rate_substance_long_day,rates_effective_from,cost_centre)
	select 	cl."owner",
			cl.loc_code,
			cl.loc_name,
			cl.loc_court_name,
			cl.loc_attend_time,
			cl.loc_address1,
			cl.loc_address2,
			cl.loc_address3,
			cl.loc_address4,
			cl.loc_address5,
			cl.loc_address6,
			cl.loc_zip,
			cl.loc_phone,
			cl.jury_officer_phone,
			cl.location_address,
			cl.region_id,
			cl.yield,
			cl.voters_lock,
			cl.term_of_service,
			cl.tdd_phone,
			cl.loc_signature,
			cl.loc_rate_mcars as rate_per_mile_car_0_passengers,
			cl.loc_rate_mcars_2 as rate_per_mile_car_1_passengers,
			cl.loc_rate_mcars_3 as rate_per_mile_car_2_or_more_passengers,
			cl.loc_rate_mcycles as rate_per_mile_motorcycle_0_passengers,
			cl.loc_rate_mcycles_2 as rate_per_mile_motorcycle_1_or_more_passengers,
			cl.loc_rate_pcycles as rate_per_mile_bike,
			coalesce(cl.loc_loss_lfour_alt,cl.loc_loss_on_half_alt)  as limit_financial_loss_half_day,
			coalesce(cl.loc_loss_mfour_alt,cl.loc_subs_mfive_alt,cl.loc_loss_overnight_alt) as limit_financial_loss_full_day,		
			cl.loc_loss_oten_alt as limit_financial_loss_half_day_long_trial,
			cl.loc_loss_mten_alt as limit_financial_loss_full_day_long_trial,
			coalesce(cl.loc_rail_bus,cl.loc_rail_bus_alt) as public_transport_soft_limit,
			cl.loc_subs_lfive_alt as rate_substance_standard,
			cl.loc_subs_mfive_alt as rate_substance_long_day,
			cl.loc_rate_transition as rates_effective_from,
			cl.loc_cost_centre as cost_centre
	from juror.court_location cl
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select COUNT(*) from target),
		"status" = 'COMPELTE'
where 	script_number = '0002a';


/*
 * reapply the foreign key constraints
 */
alter table juror_mod.appearance add constraint app_loc_code_fk foreign key (loc_code) references juror_mod.court_location(loc_code) not valid;
alter table juror_mod.court_catchment_area add constraint court_catchment_area_fk_loc_code foreign key (loc_code) references juror_mod.court_location(loc_code) not valid;
alter table juror_mod.welsh_court_location add constraint welsh_court_loc_code_fk foreign key (loc_code) references juror_mod.court_location(loc_code) not valid;
alter table juror_mod.holiday add constraint holiday_loc_code_fk foreign key (owner) references juror_mod.court_location(loc_code) not valid;
alter table juror_mod.coroner_pool add constraint coroner_pool_loc_code_fk foreign key (cor_court_loc) references juror_mod.court_location(loc_code) not valid;
alter table juror_mod.trial add constraint trial_court_loc_fk foreign key (loc_code) references juror_mod.court_location(loc_code) not valid;
alter table juror_mod.pool add constraint pool_loc_code_fk foreign key (loc_code) references juror_mod.court_location(loc_code) not valid;
alter table juror_mod.utilisation_stats add constraint utilisation_stats_fk foreign key (loc_code) references juror_mod.court_location(loc_code) not valid;

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0002a';

end $$;


-- verify results
select * from juror_mod.migration_log;
select * from juror_mod.court_location limit 10;

/*
 * court_location_audit
 * --------------------
 */

delete from juror_mod.migration_log where script_number = '0002b';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0002b', 'juror_digital', 'court_location', 'juror_mod', 'court_location_audit');


with "source" as (
	select 	count(cl.loc_code) as source_count
	from juror.court_location cl
)

update	juror_mod.migration_log
set		source_count = (select source_count from "source"),
		expected_target_count = (select source_count from "source")
where 	script_number = '0002b';

do $$

begin

alter table juror_mod.court_location_audit drop constraint if exists fk_revision_number;

truncate table juror_mod.court_location_audit;

with target 
as 
(
	insert into juror_mod.court_location_audit(revision,rev_type,loc_code,rates_effective_from,rate_per_mile_car_0_passengers,rate_per_mile_car_1_passengers,rate_per_mile_car_2_or_more_passengers,rate_per_mile_motorcycle_0_passengers,rate_per_mile_motorcycle_1_or_more_passengers,rate_per_mile_bike,limit_financial_loss_half_day,limit_financial_loss_full_day,limit_financial_loss_half_day_long_trial,limit_financial_loss_full_day_long_trial,rate_substance_standard,rate_substance_long_day,public_transport_soft_limit)
	select 	nextval('public.rev_info_seq') as revision,
	 		case 
				when rank() over(partition by cl.loc_code order by cl.loc_code,cl.loc_rate_transition) = 1
					then 0 -- first insert
					else 1 -- update
			end as rev_type,
			cl.loc_code,
			cl.loc_rate_transition as rates_effective_from,
			cl.loc_rate_mcars as rate_per_mile_car_0_passengers,
			cl.loc_rate_mcars_2 as rate_per_mile_car_1_passengers,
			cl.loc_rate_mcars_3 as rate_per_mile_car_2_or_more_passengers,
			cl.loc_rate_mcycles as rate_per_mile_motorcycle_0_passengers,
			cl.loc_rate_mcycles_2 as rate_per_mile_motorcycle_1_or_more_passengers,
			cl.loc_rate_pcycles as rate_per_mile_bike,
			coalesce(cl.loc_loss_lfour_alt,cl.loc_loss_on_half_alt)  as limit_financial_loss_half_day,
			coalesce(cl.loc_loss_mfour_alt,cl.loc_subs_mfive_alt,cl.loc_loss_overnight_alt) as limit_financial_loss_full_day,		
			cl.loc_loss_oten_alt as limit_financial_loss_half_day_long_trial,
			cl.loc_loss_mten_alt as limit_financial_loss_full_day_long_trial,
			cl.loc_subs_lfive_alt as rate_substance_standard,
			cl.loc_subs_mfive_alt as rate_substance_long_day,
			coalesce(cl.loc_rail_bus,cl.loc_rail_bus_alt) as public_transport_soft_limit
	from juror.court_location cl
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select COUNT(*) from target),
		"status" = 'COMPELTE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0002b';


alter table juror_mod.court_location_audit add constraint fk_revision_number foreign key (revision) references juror_mod.rev_info(revision_number) not valid;

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0002b';

end $$;

-- verify results
select * from juror_mod.migration_log;
select * from juror_mod.court_location_audit limit 10;
