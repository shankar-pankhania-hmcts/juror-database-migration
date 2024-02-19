-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.2;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = hk,public;

   
   -----------
   --
   -----------
CREATE OR REPLACE PROCEDURE hk.housekeeping_nocommit_delete_sa_error_log () AS $body$
DECLARE


    ora2pg_rowcount int;
l_start timestamp(0);

   
BEGIN
    
     l_start := clock_timestamp();

     DELETE FROM error_log
     WHERE  time_stamp + current_setting('housekeeping_nocommit.l_param_court_threshold')::integer < clock_timestamp();
    
     GET DIAGNOSTICS ora2pg_rowcount = ROW_COUNT;

    
     utl_file.put_line(l_file,'ERROR_LOG,'|| ora2pg_rowcount||','||TO_CHAR(l_start,'DD-MM-YYYY hh24:MI:SS')||','||TO_CHAR(clock_timestamp(),'DD-MM-YYYY hh24:MI:SS'),TRUE);

      IF p_read_only_mode THEN
        ROLLBACK;
      ELSE
        NULL;
        -- COMMIT;  **testing
      END IF;

     housekeeping_nocommit_check_time_expired;

   EXCEPTION 
     WHEN SQLSTATE '50004' THEN
       RAISE EXCEPTION 'e_timeout' USING ERRCODE = '50004';

     WHEN others THEN
  
       ROLLBACK;

       PERFORM set_config('housekeeping_nocommit.l_err_msg', SUBSTR(sqlerrm,1,200), false);
       utl_file.put_line(l_file,'ERROR Delete from ERROR_LOG',TRUE);
       utl_file.put_line(l_file,current_setting('housekeeping_nocommit.l_err_msg')::varchar(200),TRUE);

   END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE hk.housekeeping_nocommit_delete_sa_error_log () FROM PUBLIC;
