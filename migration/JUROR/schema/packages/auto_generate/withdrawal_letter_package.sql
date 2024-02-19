-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;

/****************************************************************************************************************************/

CREATE OR REPLACE PROCEDURE auto_generate_withdrawal_letter () AS $body$
BEGIN

   PERFORM set_config('auto_generate_lc_job_type', 'AUTO WITHDRAWAL LETTER GENERATION', false);
   PERFORM set_config('auto_generate_lc_englishformtype', '5224', false);
   PERFORM set_config('auto_generate_lc_welshformtype', '5224C', false);
   PERFORM set_config('auto_generate_lc_otherinformation', 'Withdrawal Letter Auto', false);
   PERFORM set_config('auto_generate_lc_historycode', 'RDIS', false);

 INSERT into temp_auto_generate_lett(part_no, pool_no, loc_code, row_id, lang, details)
 SELECT p.part_no, p.pool_no, p.loc_code, d.ROWID,CASE WHEN upper(p.welsh)='Y' THEN 'W' WHEN upper(p.welsh) IS NULL THEN 'E'  ELSE 'E' END  ,
				   current_setting('auto_generate_lc_date_part_text')::varchar(30)
				|| CASE WHEN CASE WHEN upper(p.welsh)='Y' THEN 'W' WHEN upper(p.welsh) IS NULL THEN 'E'  ELSE 'E' END ='W' THEN  RPAD(upper(cc.loc_name),40) WHEN CASE WHEN upper(p.welsh)='Y' THEN 'W' WHEN upper(p.welsh) IS NULL THEN 'E'  ELSE 'E' END ='E' THEN  CASE WHEN cc.loc_code='626' THEN RPAD(upper(cc.loc_name),59)  ELSE RPAD('The Crown Court at '||upper(cc.loc_name),59) END  END
				|| upper(current_setting('auto_generate_lc_bureau_part_text')::varchar(300))
				|| RPAD(coalesce(p.title,' '),10,' ') ||
		    	   RPAD(coalesce(p.fname,' '),20,' ') ||
		    	   RPAD(coalesce(p.lname,' '),20,' ') ||
		    	   RPAD(RPAD(coalesce(p.address,' '),35) ||
		    	   RPAD(p.address2,35) ||
		    	   RPAD(p.address3,35) ||
		    	   RPAD(p.address4,35) ||
		    	   RPAD(p.address5,35) ||
		    	   RPAD(p.address6,35) ||
		    	   RPAD(p.zip,10),220) ||
		    	   RPAD(coalesce(p.part_no,' '),9,' ')
				|| upper(current_setting('auto_generate_lc_bureau_signature')::varchar(30))
	      FROM  POOL p, DISQ_LETT d,  COURT_LOCATION cc
		  WHERE p.owner = '400'
		  AND	d.owner = '400'
		  AND	d.disq_code = 'E'
		  AND	p.loc_code = cc.loc_code
		  AND	p.is_active = 'Y'
		  AND   p.status    =  6
		  AND 	p.part_no = d.part_no
		  AND (d.printed <> 'Y' or d.printed is null);

		  CALL auto_generate_populate_abaccus();
		  CALL auto_generate_populate_part_hist();
		  CALL auto_generate_populate_print_files();

		UPDATE DISQ_LETT d 
		SET d.PRINTED = 'Y', d.DATE_PRINTED = current_setting('auto_generate_ld_begin_time')::timestamp(0)
		FROM temp_auto_generate_lett t
		WHERE  d.ROWID = t.ROW_ID AND d.OWNER = '400';

 		delete from phoenix_temp where part_no in (
			   SELECT part_no from temp_auto_generate_lett);

			   commit;

			   EXECUTE 'truncate table temp_auto_generate_lett'; -- This bit is added so that print files are not created twice
					  					  								  -- if the package is run twice in same session
 EXCEPTION
   when others then
	 CALL auto_generate_write_error(sqlerrm);
	  rollback;
	 raise;

 END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE auto_generate_withdrawal_letter () FROM PUBLIC;
