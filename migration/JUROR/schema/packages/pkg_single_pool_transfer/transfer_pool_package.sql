-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;

  
/************************************************************************
*
*	Procedure:	transfer_pool                   					 *
*
*	Access:		private													 *
*
*	Arguments:	location code											 *
*
*	Returns:	None 			                   					 *
*
*	Description:	This procedure transfers pool details, phone log, and part_hist details	*
*					from SUPS bureau to SUPS court              		 *
*									   		  	  						 *
*	Name		Date		Action										 *
*	====		====		======										 *
*	Joy       15/09/05		Created this procedure						 *
************************************************************************/
CREATE OR REPLACE PROCEDURE pkg_single_pool_transfer_transfer_pool (p_pool_no text) AS $body$
DECLARE


ln_debug_no_rows bigint:=0;

-- Cursor for pool records
C2_pool_records CURSOR(p_pool_no text) FOR
       SELECT p.oid row_id, p.* 
       FROM pool p
       WHERE  p.status IN (1,2)
       AND p.owner='400' 
       and (p.read_only='N' or p.read_only is null) 
       and  p.pool_no = p_pool_no;

BEGIN

-- For debug only.
  select count(*)
  into STRICT ln_debug_no_rows 
  FROM pool p
       WHERE  p.status IN (1,2)
       AND p.owner='400' 
       and (p.read_only='N' or p.read_only is null) 
       and  p.pool_no = p_pool_no;

           
For Pool_records in C2_pool_records(p_pool_no)
Loop
EXIT WHEN NOT FOUND; /* apply on C2_pool_records */

 INSERT INTO pool(owner,part_no,
						pool_no,
						poll_number,
						title,
						lname,
						fname,
						dob,
						address,
						address2,
						address3,
						address4,
                        address5,
                        address6,
                        zip,
                        h_phone,
                        w_phone,
                        w_ph_local,
                        times_sel,
                        trial_no,
                        juror_no,
                        reg_spc,
                        ret_date,
                        def_date,
                        responded,
                        date_excus,
                        exc_code,
                        acc_exc,
                        date_disq,
                        disq_code,
                        mileage,
                        location,
                        user_edtq,
                        status,
                        notes,
                        no_attendances,
                        is_active,
                        no_def_pos,
                        no_attended,
                        no_fta,
                        no_awol,
                        pool_seq,
                        edit_tag,
                        pool_type,
                        loc_code,
                        next_date,
                        on_call,
                        perm_disqual,
                        pay_county_emp,
                        pay_expenses,
                        spec_need,
                        spec_need_msg,
                        smart_card,
                        amt_spent,
                        completion_flag,
                        completion_date,
                        sort_code,
                        bank_acct_name,
                        bank_acct_no,
                        bldg_soc_roll_no,
                        was_deferred,
                        id_checked,
                        postpone,
                        welsh,
                        paid_cash,
                        travel_time,
                        scan_code,
                        financial_loss,
                        police_check,
                        last_update,
                        read_only,
                        summons_file,
                        reminder_sent,
                        phoenix_date,
                        phoenix_checked)
			VALUES (current_setting('pkg_single_pool_transfer_ld_location_code')::varchar(9),
                         pool_records.part_no,
                         pool_records.pool_no,
                         pool_records.poll_number,
                         pool_records.title,
                         pool_records.lname,
                         pool_records.fname,
                         pool_records.dob,
                         pool_records.address,
                         pool_records.address2,
                         pool_records.address3,
                         pool_records.address4,
                         pool_records.address5,
                         pool_records.address6,
                         pool_records.zip,
                         pool_records.h_phone,
                         pool_records.w_phone,
                         pool_records.w_ph_local,
                         pool_records.times_sel,
                         pool_records.trial_no,
                         pool_records.juror_no,
                         pool_records.reg_spc,
                         pool_records.ret_date,
                         pool_records.def_date,
                         pool_records.responded,
                         pool_records.date_excus,
                         pool_records.exc_code,
                         pool_records.acc_exc,
                         pool_records.date_disq,
                         pool_records.disq_code,
                         pool_records.mileage,
                         pool_records.location,
                         pool_records.user_edtq,
                         pool_records.status,
                         pool_records.notes,
                         pool_records.no_attendances,
                         pool_records.is_active,
                         pool_records.no_def_pos,
                         pool_records.no_attended,
                         pool_records.no_fta,
                         pool_records.no_awol,
                         pool_records.pool_seq,
                         pool_records.edit_tag,
                         pool_records.pool_type,
                         pool_records.loc_code,
                         pool_records.next_date,
                         pool_records.on_call,
                         pool_records.perm_disqual,
                         pool_records.pay_county_emp,
                         pool_records.pay_expenses,
                         pool_records.spec_need,
                         pool_records.spec_need_msg,
                         pool_records.smart_card,
                         pool_records.amt_spent,
                         pool_records.completion_flag,
                         pool_records.completion_date,
                         pool_records.sort_code,
                         pool_records.bank_acct_name,
                         pool_records.bank_acct_no,
                         pool_records.bldg_soc_roll_no,
                         pool_records.was_deferred,
                         pool_records.id_checked,
                         pool_records.postpone,
                         pool_records.welsh,
                         pool_records.paid_cash,
                         pool_records.travel_time,
                         pool_records.scan_code,
                         pool_records.financial_loss,
                         pool_records.police_check,
                         pool_records.last_update,
                         'N',
                         pool_records.summons_file,
                         pool_records.reminder_sent,
                         pool_records.phoenix_date,
                         pool_records.phoenix_checked);

	 -- Update the read_only flag in the bureau side
	 UPDATE pool SET read_only ='Y'
	 WHERE rowid = pool_records.row_id;

   -- Insert into the part_hist details
   INSERT INTO part_hist(Owner,part_no,date_part,history_code,user_id,other_information,pool_no)
   SELECT  current_setting('pkg_single_pool_transfer_ld_location_code')::varchar(9), part_no,date_part,history_code,user_id,other_information,pool_no
   FROM	part_hist
   WHERE	owner = '400'
   AND		part_no = pool_records.part_no;

   -- Insert into the  phone_log table
   INSERT INTO phone_log(owner,part_no,start_call,user_id,end_call,phone_code,notes)
	 SELECT current_setting('pkg_single_pool_transfer_ld_location_code')::varchar(9), part_no,start_call,user_id,end_call,phone_code,notes
	 FROM	phone_log
	 WHERE	owner = '400'
	 AND	part_no = pool_records.part_no;

 End Loop;

 Exception
		 WHEN OTHERS THEN
			 CALL pkg_single_pool_transfer_write_error_message('POOL TRANSFER','Error in TRANSFER_POOL Package. '||SUBSTR(SQLERRM, 1, 100));
			   rollback;
			   raise;

END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE pkg_single_pool_transfer_transfer_pool (p_pool_no text) FROM PUBLIC;
