/* 
 * Task: 5300
 * 
 * Migrate data from JUROR.JUROR_RESPONSE → juror_mod.juror_response
 * Migrate data from JUROR.STAFF_JUROR_RESPONSE_AUDIT → juror_mod.staff_juror_response_audit
 * Migrate data from JUROR.JUROR_RESPONSE_AUD → juror_mod.juror_response_aud
 * Migrate data from JUROR.RESPONSE_CJS_EMPLOYMENT → juror_mod.response_cjs_employment
 * Migrate data from JUROR.RESPONSE_SPECIAL_NEEDS → juror_mod.juror_reasonable_adjustment
 * Migrate data from all migrated data will have the reply_type of DIGITAL
 * 
 */

ALTER TABLE juror_mod.juror_response 
	DROP CONSTRAINT IF EXISTS juror_response_juror_number_fkey;

ALTER TABLE juror_mod.juror_response 
	DROP CONSTRAINT IF EXISTS juror_response_reply_type_fkey;


ALTER TABLE juror_mod.juror_response_aud 
	DROP CONSTRAINT IF EXISTS juror_response_aud_juror_number_fkey;

ALTER TABLE juror_mod.juror_response_cjs_employment 
	DROP CONSTRAINT IF EXISTS juror_response_cjs_employment_juror_number_fkey;

ALTER TABLE juror_mod.staff_juror_response_audit 
	DROP CONSTRAINT IF EXISTS staff_juror_response_audit_juror_number_fkey;

/*
 * Migrate data from JUROR.JUROR_RESPONSE → juror_mod.juror_response
 */
truncate table juror_mod.juror_response;

with rows
as
(
 	INSERT into juror_mod.juror_response (juror_number,first_name,last_name,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode,alt_phone_number,bail,bail_details,completed_at,convictions,convictions_details,date_of_birth,date_received,deferral_date,deferral_reason,email,email_address,excusal_reason,juror_email_details,juror_phone_details,main_phone,mental_health_act,mental_health_act_details,other_phone,phone_number,processing_complete,processing_status,relationship,residency,residency_detail,staff_assignment_date,staff_login,thirdparty_fname,thirdparty_lname,thirdparty_other_reason,thirdparty_reason,title,urgent,super_urgent,welsh,version,reply_type)
	SELECT distinct 
			jr.juror_number,
			jr.first_name,
			jr.last_name,
			jr.address,
			jr.address2,
			jr.address3,
			jr.address4,
			RTRIM(jr.address5||' '||jr.address6) as address5,
			jr.zip,
			jr.alt_phone_number,
			case UPPER(jr.bail)
				when 'Y' 
					then true
					else false
			end,
			jr.bail_details,
			jr.completed_at,
			case UPPER(jr.convictions)
				when 'Y' 
					then true
					else false
			end,
			jr.convictions_details,
			jr.date_of_birth,
			jr.date_received,
			jr.deferral_date,
			jr.deferral_reason,
			jr.email,
			jr.email_address,
			jr.excusal_reason,
			case UPPER(jr.juror_email_details)
				when 'Y' 
					then true
					else false
			end,
			case UPPER(jr.juror_phone_details)
				when 'Y' 
					then true
					else false
			end,
			jr.main_phone,
			case UPPER(jr.mental_health_act)
				when 'Y' 
					then true
					else false
			end,
			jr.mental_health_act_details,
			jr.other_phone,
			jr.phone_number,
			case UPPER(jr.processing_complete)
				when 'Y' 
					then true
					else false
			end,
			jr.processing_status,
			jr.relationship,
			case UPPER(jr.residency)
				when 'Y' 
					then true
					else false
			end,
			jr.residency_detail,
			jr.staff_assignment_date,
			jr.staff_login,
			jr.thirdparty_fname,
			jr.thirdparty_lname,
			jr.thirdparty_other_reason,
			jr.thirdparty_reason,
			jr.title,
			case UPPER(jr.urgent)
				when 'Y' 
					then true
					else false
			end,
			case UPPER(jr.super_urgent)
				when 'Y' 
					then true
					else false
			end,
			case UPPER(jr.welsh)
				when 'Y' 
					then true
					else false
			end,
			jr.version,
			'Digital' as reply_type
	FROM juror_digital.juror_response jr
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected


-- verify results
select count(*) FROM juror_digital.juror_response;
select * FROM juror_mod.juror_response limit 10;


/* Migrate data from JUROR.STAFF_JUROR_RESPONSE_AUDIT → juror_mod.staff_juror_response_audit */

truncate juror_mod.staff_juror_response_audit;

WITH rows AS (
	insert into juror_mod.staff_juror_response_audit(juror_number,created,date_received,staff_assignment_date,staff_login,team_leader_login,version)
	SELECT DISTINCT 
			sjra.juror_number,
			sjra.created,
			sjra.date_received,
			sjra.staff_assignment_date,
			sjra.staff_login,
			sjra.team_leader_login,
			sjra.version
	FROM juror_digital.staff_juror_response_audit sjra
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected
 
-- verify results
select count(*) FROM juror_digital.staff_juror_response_audit;
select * FROM juror_mod.staff_juror_response_audit limit 10;


/* Migrate data from JUROR_DIGITAL.JUROR_RESPONSE_AUD → juror_mod.juror_response_aud */

truncate juror_mod.juror_response_aud;

WITH rows AS (
	insert into juror_mod.juror_response_aud(changed,juror_number,login,new_processing_status,old_processing_status)
	SELECT DISTINCT 
			jra.changed,
			jra.juror_number,
			jra.login,
			jra.new_processing_status,
			jra.old_processing_status
	FROM juror_digital.juror_response_aud jra
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected
 
-- verify results
select count(*) FROM juror_digital.juror_response_aud;
select * FROM juror_mod.juror_response_aud limit 10;


/* Migrate data from JUROR.RESPONSE_CJS_EMPLOYMENT → juror_mod.response_cjs_employment */

truncate juror_mod.juror_response_cjs_employment RESTART IDENTITY cascade;

WITH rows AS (
	insert into juror_mod.juror_response_cjs_employment(juror_number,cjs_employer,cjs_employer_details)
	select distinct 
			jrce.juror_number,
			jrce.cjs_employer,
			jrce.cjs_employer_details
	from juror_digital.juror_response_cjs_employment jrce 
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected 
 
-- verify results
select count(*) FROM juror_digital.juror_response_cjs_employment;
select * FROM juror_mod.juror_response_cjs_employment limit 10;


/* 
 * Migrate data from JUROR.RESPONSE_SPECIAL_NEEDS → juror_mod.juror_reasonable_adjustment
*/

truncate juror_mod.juror_reasonable_adjustment RESTART IDENTITY cascade;

WITH rows AS (
	insert into juror_mod.juror_reasonable_adjustment(juror_number,reasonable_adjustment,reasonable_adjustment_detail)
	SELECT DISTINCT 
			jrsn.juror_number,
			jrsn.spec_need,
			jrsn.spec_need_detail
	FROM juror_digital.juror_response_special_needs jrsn
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected
 
-- verify results
select count(*) FROM juror_digital.juror_response_special_needs;
select * FROM juror_mod.juror_reasonable_adjustment limit 10;


ALTER TABLE juror_mod.juror_response 
	ADD CONSTRAINT juror_response_juror_number_fkey FOREIGN KEY (juror_number) REFERENCES juror_mod.juror(juror_number) NOT valid;

ALTER TABLE juror_mod.juror_response 
	ADD CONSTRAINT juror_response_reply_type_fkey FOREIGN KEY (reply_type) REFERENCES juror_mod.t_reply_type(type) not VALID;

ALTER TABLE juror_mod.juror_response_aud 
	ADD CONSTRAINT juror_response_aud_juror_number_fkey FOREIGN KEY (juror_number) REFERENCES juror_mod.juror_response(juror_number) not VALID;

ALTER TABLE juror_mod.juror_response_cjs_employment 
	ADD CONSTRAINT juror_response_cjs_employment_juror_number_fkey FOREIGN KEY (juror_number) REFERENCES juror_mod.juror_response(juror_number) not VALID;

ALTER TABLE juror_mod.staff_juror_response_audit 
	ADD CONSTRAINT staff_juror_response_audit_juror_number_fkey FOREIGN KEY (juror_number) REFERENCES juror_mod.juror_response(juror_number) not VALID;