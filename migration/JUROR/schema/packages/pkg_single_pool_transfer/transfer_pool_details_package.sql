-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;
SET CLIENT_MIN_MESSAGES = 'notice';



CREATE OR REPLACE PROCEDURE pkg_single_pool_transfer_transfer_pool_details (p_pool_no text) AS $body$
DECLARE


   ln_no_pool_recs bigint := 0;
   ln_no_unip_recs bigint := 0;
   ln_no_part_recs bigint := 0;
   ln_no_plog_recs bigint := 0;

   
BEGIN

      PERFORM set_config('pkg_single_pool_transfer_ld_location_code', SUBSTR(p_pool_no, 1, 3), false);
      RAISE NOTICE 'Pool: %', p_pool_no;

      Begin
         -- Transfer the POOL records.
         CALL pkg_single_pool_transfer_transfer_pool(p_pool_no);

         -- Transfer the UNIQUE_POOL records.
         CALL pkg_single_pool_transfer_transfer_court_unique_pool(p_pool_no, current_setting('pkg_single_pool_transfer_ld_location_code')::varchar(9));

         -- This block for debug info only.
         select count(*) into STRICT ln_no_unip_recs from unique_pool;
         select count(*) into STRICT ln_no_pool_recs from pool where pool_no in (SELECT pool_no from unique_pool where pool_no like(current_setting('pkg_single_pool_transfer_ld_location_code')::varchar(9) || '%'));
         select count(*) into STRICT ln_no_plog_recs from phone_log;
         select count(*) into STRICT ln_no_part_recs from part_hist;

	       commit; -- commit the transaction for each court.
         --rollback;
         RAISE NOTICE 'Rollback %', p_pool_no;
               
	       EXCEPTION
		      WHEN OTHERS THEN
			    CALL pkg_single_pool_transfer_write_error_message('POOL TRANSFER', 'LOC_CODE :'||p_pool_no||' : '||SQLERRM);
			    rollback;
			    PERFORM set_config('pkg_single_pool_transfer_g_job_status', false, false);
      End;

      IF NOT current_setting('pkg_single_pool_transfer_g_job_status')::boolean THEN
			  RAISE EXCEPTION '%', 'Error in Pool Transfer Procedure. Not all pools are transferred.' USING ERRCODE = '45001';
			  RAISE EXCEPTION '%', 'Check ERROR_LOG table for failed Locations.' USING ERRCODE = '45001';
			END IF;

      EXCEPTION
		    WHEN OTHERS THEN
			  CALL pkg_single_pool_transfer_write_error_message('POOL TRANSFER', SQLERRM);
			  rollback;
			  raise;

	END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE pkg_single_pool_transfer_transfer_pool_details (p_pool_no text) FROM PUBLIC;
