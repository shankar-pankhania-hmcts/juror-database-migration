-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.4;sid=xe;port=1521

SET client_encoding TO 'UTF8';

\set ON_ERROR_STOP ON

CREATE OR REPLACE PACKAGE POOL_TRANSFER AS

   PROCEDURE transfer_pool_details;

END POOL_TRANSFER;





CREATE OR REPLACE PACKAGE BODY POOL_TRANSFER AS

-- Declare public variables
    ld_EffectiveDate		DATE;
	ld_LatestReturnDate		DATE;
	ln_deadline number := 10;
	g_job_status  boolean := true;


--Declare the procedures
PROCEDURE write_error_message(p_job varchar2, p_Message varchar2);
PROCEDURE get_return_date(pn_deadline number , pd_LatestReturnDate OUT DATE);
PROCEDURE transfer_pool(location_code varchar2);
PROCEDURE transfer_court_unique_pool(location_code varchar2);
/*************************************************************************************************************
 *
 *
 *	Procedure:	pool_transfer.transfer_pool_details
 *
 *
 *	Access:		public
 *
 *
 *	Arguments:	none
 *
 *
 *	Returns:	none
 *
 *
 *	Description:	
 *			transfer pool, part_hist , phone log and part_amendments detail
 *          data from the Bureau to Courts and
 *			insert or update the data accordingly
 *
 *
 *	Name		Date		Action
 *	====		====		======
 *	Joy     15/09/05	Created
 *  Jeeva		01/12/05	Changed from writing Error Logs to OS file to  writing to ERROR_LOG table
 *  Chris W 20/11/15  Get ln_deadline from system paramter table
 *  Pete T 	06/04/16	Included h_email and contact_preference for Text/email
 *****************************************************************************************************************/


/************* Transfer_pool_details ********************/
PROCEDURE transfer_pool_details is


  Cursor C1_sups_courts  is select distinct(owner) owner from unique_pool where owner <>'400';

    Begin

      Select SP_VALUE into ln_DeadLine from system_parameter where SP_ID = 7;
      IF ln_deadline is null THEN
         ln_deadline := 10;
      END IF;

      get_return_date(ln_DeadLine, ld_LatestReturnDate);

      For  location_codes in  C1_sups_courts
      Loop
	        Begin
	           transfer_pool(location_codes.owner);
	           Transfer_court_unique_pool(location_codes.owner);
	           commit; -- commit the transaction for each court.
	           EXCEPTION
		                  WHEN OTHERS THEN
			                write_error_message('POOL TRANSFER', 'LOC_CODE :'||location_codes.owner||' : '||SQLERRM);
			                rollback;
			                g_job_status := false;
	       End;
      End loop;
			IF NOT g_job_status THEN
			  raise_application_error(-20001, 'Error in Pool Transfer Procedure. Not all pools are transferred.');
			  raise_application_error(-20001, 'Check ERROR_LOG table for failed Locations.');
			END IF;

    EXCEPTION
		    WHEN OTHERS THEN
			  write_error_message('POOL TRANSFER', SQLERRM);
			  rollback;
			  raise;
	End  transfer_pool_details;
/************************************************************************************************/
/************************************************************************
 *
*
 *	Procedure:	get_return_date                    					 *
 *
*
 *	Access:		private													 *
 *
*
 *	Arguments:	Deadline as NUMBER		 								 *
 *
 *
 *	Returns:	latest return date as DATE 								 *
 *
 *
 *	Description:	This procedure  accepts  deadline as input			 *
 *					If the procedure is run on a Friday after 6 pm		 *
 *					it will return the latest return date 	  			 *
 *					For any other day, this procedure will find the 	 *
 *					nearest friday which has passed and accordinly 		 *
 *					compute the latest return date						 *
 *									   		  	  						 *
 *
 *	Name	  	Date		 Action										 *
 *	====		  ====		 ======										 *
 *	Joy       15/09/05 Created this procedure						 *
 *	Kal Sohal 17/01/07 v1.5 SCR 4362 - Pools transferring too early.
 *                     Modify code which determines if procedure is being run before 6pm on a Friday by
 *                     reference to the dates day number 6 with NEW reference to actual dates day name 'fri'.
 *  Chris W   20/11/15 Get deadline from court_location table
 ************************************************************************/

PROCEDURE get_return_date(pn_DeadLine NUMBER, pd_LatestReturnDate OUT DATE) IS
	ln_Day	 varchar2(3);
begin
    ld_EffectiveDate := sysdate;
  	IF ((TO_NUMBER(TO_CHAR(ld_EffectiveDate,'sssss')) <= 64800)
       AND (TO_CHAR(ld_EffectiveDate,'dy') = 'fri'))  THEN -- Set the effective date to previous day
 		   ld_EffectiveDate := TRUNC(ld_EffectiveDate)-1; 	      -- if the procedure runs before 6 pm on a Friday
 		END IF;
    ln_Day := TO_CHAR(ld_EffectiveDate,'dy');
    CASE ln_Day
      WHEN 'mon' THEN ld_EffectiveDate := TRUNC(ld_EffectiveDate - 3); -- Monday
      WHEN 'tue' THEN ld_EffectiveDate := TRUNC(ld_EffectiveDate - 4); -- Tuesday
      WHEN 'wed' THEN ld_EffectiveDate := TRUNC(ld_EffectiveDate - 5); -- Wednesday
      WHEN 'thu' THEN ld_EffectiveDate := TRUNC(ld_EffectiveDate - 6); --Thursday
      WHEN 'fri' THEN ld_EffectiveDate := TRUNC(ld_EffectiveDate); -- Friday
      WHEN 'sat' THEN ld_EffectiveDate := TRUNC(ld_EffectiveDate - 1 ); -- Saturday
      WHEN 'sun' THEN ld_EffectiveDate := TRUNC(ld_EffectiveDate - 2); --Sunday
		END CASE;
    pd_LatestReturnDate   := ld_EffectiveDate + pn_DeadLine + 5;


END get_return_date;
/**************************************************************************************************
 *
 *
 *	Procedure:	transfer_pool
 *
 *
 *	Access:		private
 *
 *
 *	Arguments:	location code
 *
 *
 *	Returns:	None
 *
 *
 *	Description:	This procedure transfers pool details, phone log, and part_hist details
 *					from SUPS bureau to SUPS court
 *
 *
 *	Name		     Date 		Action
 *	====		     ====     ======
 *	Joy          15/09/05	Created this procedure
 *  C Davies     06/05/10 RFC 1571 - Included transfer of PART_AMENDMENTS table
 *  Chris W      04/04/13 RFS 3681 Transfer juror records having status 11 (Awaiting Info)
 *  Chris W      20/11/15 Get pool transfer adjustment from court_location table
 *                       - enables early transfer of pools
 *                         e.g. set adjustment to 7 to bring the pool transfer window a week earlier
 *********************************************************************************************************/
PROCEDURE transfer_pool(location_code varchar2) is

-- Cursor for pool records
-- RFS 3681 included status 11
Cursor C2_pool_records(cp_loc_code varchar2) is SELECT p.rowid row_id, p.* FROM pool p
			WHERE  p.status IN (1,2,11)
			AND p.owner='400' and (p.read_only='N' or p.read_only is null) 
      and  p.pool_no in ( SELECT pool_no from  unique_pool u, court_location c
				WHERE  read_only = 'N'
        and c.loc_code = u.loc_code
				AND u.owner='400' AND TRUNC(return_date) <= ld_LatestReturnDate + nvl(pool_transfer_adjustment_days,0)
				AND  u.loc_code in (select loc_code from context_data where context_id = cp_loc_code));

Begin

For Pool_records in C2_pool_records(location_code)
Loop
EXIT when C2_pool_records%NOTFOUND;

  -- RFS 3681 decode status 2 > 2, others > 1
  INSERT INTO pool (owner,part_no,
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
                        phoenix_checked,
                        m_phone,
			h_email,
			contact_preference)
			VALUES      (location_code,
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
                         decode(pool_records.status,2,2,1),
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
                         pool_records.phoenix_checked, 
                         pool_records.m_phone,
			pool_records.h_email,
			pool_records.contact_preference);

	 -- Update the read_only flag in the bureau side
	 UPDATE pool SET read_only ='Y'
	 WHERE rowid = pool_records.row_id;



-- Insert into the part_hist details

	INSERT INTO part_hist (Owner,part_no,date_part,history_code,user_id,other_information,pool_no)
	SELECT  location_code, part_no,date_part,history_code,user_id,other_information,pool_no
	FROM	part_hist
	WHERE	owner = '400'
	AND		part_no = pool_records.part_no;


-- Insert into the  phone_log table
     INSERT INTO phone_log (owner,part_no,start_call,user_id,end_call,phone_code,notes)
	 SELECT location_code, part_no,start_call,user_id,end_call,phone_code,notes
	 FROM	phone_log
	 WHERE	owner = '400'
	 AND	part_no = pool_records.part_no;


-- RFC 1571 Insert into the  part_amendments table
        INSERT INTO part_amendments (owner,part_no,edit_date,edit_userid,title,fname,lname, dob, address, zip,sort_code, bank_acct_name, bank_acct_no, bldg_soc_roll_no, pool_no )
	    SELECT location_code, part_no,edit_date,edit_userid,title,fname,lname, dob, address, zip,sort_code, bank_acct_name, bank_acct_no, bldg_soc_roll_no, pool_no
	    FROM	part_amendments
	    WHERE	owner = '400'
	    AND	        part_no = pool_records.part_no;
 End Loop;

 Exception
		 WHEN OTHERS THEN
			 write_error_message('POOL TRANSFER','Error in TRANSFER_POOL Package. '||SUBSTR(SQLERRM, 1, 100));
			   rollback;
			   raise;

End transfer_pool;
/**************************************************************************************************/
/************************************************************************
*
*
*	Procedure:	transfer_court_unique_pool                   			 *
*
*
*	Access:		private													 *
*
*
 *	Arguments:	location code											 *
 *
 *
 *	Returns:	None 			                   					 *
 *
 *
 *	Description:	This procedure transfers pool reuests created at bureau for the courts
 * 					from SUPS bureau to SUPS court              		 *
 *									   		  	  						 *
 *
 *	Name		  Date		  Action										 *
 *	====		  ====		  ======										 *
 *	Joy       21/09/05	Created this procedure						 *
 *  Chris W   20/11/15  Get pool transfer adjustment from court_location table
 *                       - enables early transfer of pools
 *                         e.g. set adjustment to 7 to bring the pool transfer window a week earlier
 ************************************************************************/

Procedure transfer_court_unique_pool(location_code varchar2) is
ln_up_ins_records number:=0;
ln_up_found number:=0;
Cursor C5_unique_pool(location_code varchar2) is
          SELECT  pool_no,
		   		  jurisdiction_code,
				  TRUNC(return_date) return_date,
				  next_date,
				  pool_total,
				  no_requested,
				  reg_spc,
				  pool_type,
				  u.loc_code,
				  new_request,
				  read_only
		   FROM	  unique_pool u, court_location c
		   WHERE u.owner = '400'
       AND read_only = 'N'
       and c.loc_code = u.loc_code
		   AND TRUNC(return_date) <= ld_LatestReturnDate + nvl(pool_transfer_adjustment_days,0)
		   AND  u.loc_code in (select loc_code from context_data where context_id = location_code);

Begin
	 For unique_pool_recs in c5_unique_pool(location_code)
	 Loop
	 EXIT when c5_unique_pool%NOTFOUND;

	 SELECT count(1)
	 INTO ln_up_found
	 FROM unique_pool
	 WHERE OWNER=location_code
	 AND  pool_no= unique_pool_recs.pool_no;

     IF ln_up_found = 0 THEN

 			INSERT INTO unique_pool(owner,
					   		  	   			   pool_no,
											   jurisdiction_code,
											   return_date,
											   next_date,
											   pool_total,
											   no_requested,
											   reg_spc,
											   pool_type,
											   loc_code,
											   new_request,
											   read_only)
					  				    VALUES ( location_code,unique_pool_recs.pool_no,
											   unique_pool_recs.jurisdiction_code,
											   unique_pool_recs.return_date,
											   unique_pool_recs.next_date,
											   unique_pool_recs.pool_total,
											   unique_pool_recs.no_requested,
											   unique_pool_recs.reg_spc,
											   unique_pool_recs.pool_type,
											   unique_pool_recs.loc_code,
											   'N',
											   'N'
											   );
						ln_up_ins_records := ln_up_ins_records+ SQL%rowcount;


   Else
                   UPDATE unique_pool
				   SET	  jurisdiction_code  = unique_pool_recs.jurisdiction_code,
				   		  return_date 	   	 = unique_pool_recs.return_date,
						  next_date		   	 = unique_pool_recs.next_date,
						  pool_total	   	 = unique_pool_recs.pool_total,
						  no_requested	   	 = unique_pool_recs.no_requested,
						  reg_spc		   	 = unique_pool_recs.reg_spc,
						  pool_type		   	 = unique_pool_recs.pool_type,
						  loc_code		   	 = unique_pool_recs.loc_code,
						  new_request	   	 = 'N',
						  read_only		   	 = decode('OWNER','400','Y','N')
					WHERE pool_no = unique_pool_recs.pool_no;

   End If;
	-- update unique_pool read_only flag in Bureau
			UPDATE unique_pool SET read_only ='Y'
			, new_request = 'N'
			WHERE pool_no = unique_pool_recs.pool_no
			AND owner ='400';
End loop;

Exception
	when others then
		write_error_message('POOL TRANSFER','Error in TRANSFER_COURT_UNIQUE_POOL Package. '||SUBSTR(SQLERRM, 1, 100));
		rollback;
		raise;
END transfer_court_unique_pool;

  /*******************************************************************************************************************/


  PROCEDURE write_error_message(p_job varchar2, p_Message varchar2) is
   pragma autonomous_transaction;
  BEGIN
   INSERT INTO ERROR_LOG (job, error_info) values (p_job, p_Message );
	commit;
  END write_error_message;

END POOL_TRANSFER;
