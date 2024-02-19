/*
 * Task: 5213
 * 
 * JUROR
 * -----
 * 
 * Migrate data from JUROR.POOL into JUROR_MOD.JUROR
 */

/*
 * Disable any foreign keys prior to deleting any previous data in the new schema
 * Note that simply disabling the FK on the table will not have any effect due to system tables permissions 
 * so the only option is to remove and then re-add them.
 * 
 */
ALTER TABLE juror_mod.juror_pool
   DROP CONSTRAINT IF exists juror_pool_fk_juror; 

ALTER TABLE juror_mod.juror_response
   DROP CONSTRAINT IF EXISTS juror_response_juror_number_fkey;

ALTER TABLE juror_mod.bulk_print_data
   DROP CONSTRAINT IF EXISTS bulk_print_data_juror_no_fk;

ALTER TABLE juror_mod.contact_log
   DROP CONSTRAINT IF EXISTS juror_number_fk;

ALTER TABLE juror_mod.juror_history
   DROP CONSTRAINT IF EXISTS juror_history_fk;

ALTER TABLE juror_mod.juror
   DROP CONSTRAINT IF EXISTS police_check_val;

    
TRUNCATE juror_mod.juror;

WITH last_updated 
as
(
	SELECT distinct
			p.part_no, 
			p.pool_no,
			p.owner,
			p.last_update,
			RANK() OVER (
		    PARTITION BY p.part_no
		    ORDER BY p.part_no, p.last_update desc) as ranking -- identify the last record updated for the juror
	from juror.pool p
	where p.read_only = 'N'
),
rows 
AS 
(
	INSERT into juror_mod.juror(juror_number,poll_number,title,last_name,first_name,dob,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode,h_phone,w_phone,w_ph_local,responded,date_excused,excusal_code,acc_exc,date_disq,disq_code,user_edtq,notes,no_def_pos,perm_disqual,smart_card,completion_date,sort_code,bank_acct_name,bank_acct_no,bldg_soc_roll_no,welsh,police_check,last_update,summons_file,m_phone,h_email,contact_preference,notifications,optic_reference,date_created,travel_time)
	SELECT DISTINCT 
			p.part_no,
			MAX(p.poll_number) as poll_number,
			MAX(p.title) as title,
			MAX(p.lname) as last_name,
			MAX(p.fname) as first_name,
			MAX(p.dob) as dob,
			MAX(p.address) as address_line_1,
			MAX(p.address2) as address_line_2,
			MAX(p.address3) as address_line_3,
			MAX(p.address4) as address_line_4,
			rtrim(MAX(p.address5)||' '||MAX(p.address6)) as address_line_5,
			MAX(p.zip) as postcode,
			MAX(p.h_phone) as h_phone,
			MAX(p.w_phone) as w_phone,
			MAX(p.w_ph_local) as w_ph_local,
			case MAX(UPPER(p.responded))
				when 'Y' 
					then true
					else false
			end as responded,
			MAX(p.date_excus) as date_excused,
			MAX(p.exc_code) as excusal_code,
			MAX(p.acc_exc) as acc_exc,
			MAX(p.date_disq) as date_disq,
			MAX(p.disq_code) as disq_code,
			MAX(p.user_edtq) as user_edtq,
			MAX(p.notes) as notes,
			MAX(p.no_def_pos) as no_def_pos,
			case MAX(UPPER(p.perm_disqual))
				when 'Y' 
					then true
					else false
			end as perm_disqual,
			MAX(p.smart_card) as smart_card,
			MAX(p.completion_date) as completion_date,
			MAX(p.sort_code) as sort_code,
			MAX(p.bank_acct_name) as bank_acct_name,
			MAX(p.bank_acct_no) as bank_acct_no,
			MAX(p.bldg_soc_roll_no) as bldg_soc_roll_no,
			case MAX(UPPER(p.welsh))
				when 'Y' 
					then true
					else false
			end as welsh,
			case 
				when MAX(p.police_check) = 'E'
					then 'IN_PROGRESS'
				when MAX(p.police_check) = 'P' and MAX(p.phoenix_checked) = 'C'
					then 'ELIGIBLE'
				when MAX(p.police_check) = 'C' and MAX(p.phoenix_checked) = 'F'
					then 'INELIGIBLE'
				when MAX(p.phoenix_checked) = 'U'
					then 'UNCHECKED_MAX_RETRIES_EXCEEDED'
				when MAX(p.police_check) = 'I' 
					then 'INSUFFICIENT_INFORMATION'
					else NULL
			end as police_check,
			MAX(p.last_update) as last_update,
			MAX(p.summons_file) as summons_file,
			MAX(p.m_phone) as m_phone,
			MAX(p.h_email) as h_email,
			MAX(p.contact_preference) as contact_preference,
			MAX(p.notifications) as notifications,
			null as optic_reference,
			MAX(lu.last_update) as last_update,
			MAX(p.travel_time)*'1 HOUR'::interval as travel_time_time
	FROM juror.pool p
	join last_updated lu  
	on p.part_no = lu.part_no
	and p.pool_no = lu.pool_no
	and p.owner = lu.owner
	and p.last_update = lu.last_update
	and lu.ranking = 1  -- required to filter out duplicates - return only the latest update for the juror
	where p.read_only = 'N'
	GROUP BY p.part_no
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected

-- Recreate any foreign keys but ignore checks on existing data
ALTER TABLE juror_mod.juror_pool
   ADD CONSTRAINT juror_pool_fk_juror foreign key (juror_number) references juror_mod.juror(juror_number) NOT valid;

ALTER TABLE juror_mod.juror_response
   ADD CONSTRAINT juror_response_juror_number_fkey foreign key (juror_number) references juror_mod.juror(juror_number)  NOT VALID;

ALTER TABLE juror_mod.bulk_print_data
   ADD CONSTRAINT bulk_print_data_juror_no_fk foreign key (juror_nO) references juror_mod.juror(juror_number) NOT VALID;

ALTER TABLE juror_mod.contact_log
   ADD CONSTRAINT juror_number_fk foreign key (juror_number) references juror_mod.juror(juror_number) NOT VALID;

ALTER TABLE juror_mod.juror_history
   ADD CONSTRAINT juror_history_fk foreign key (juror_number) references juror_mod.juror(juror_number) NOT VALID;

ALTER TABLE juror_mod.juror 
	ADD CONSTRAINT police_check_val CHECK (((police_check)::text = ANY ((ARRAY[
	'INSUFFICIENT_INFORMATION'::character varying, 
	'NOT_CHECKED'::character varying, 
	'IN_PROGRESS'::character varying, 
	'ELIGIBLE'::character varying, 
	'INELIGIBLE'::character varying, 
	'ERROR_RETRY_NAME_HAS_NUMERICS'::character varying, 
	'ERROR_RETRY_CONNECTION_ERROR'::character varying, 
	'ERROR_RETRY_OTHER_ERROR_CODE'::character varying, 
	'ERROR_RETRY_NO_ERROR_REASON'::character varying, 
	'ERROR_RETRY_UNEXPECTED_EXCEPTION'::character varying, 
	'UNCHECKED_MAX_RETRIES_EXCEEDED'::character varying])::text[])));

  
-- verify results
select count(distinct part_no) FROM juror.pool p where p.read_only = 'N';
select * FROM juror_mod.juror j limit 10;
