-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.2;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = hk,public;

 
   -----------
   --
   -----------
CREATE OR REPLACE PROCEDURE hk.housekeeping_nocommit_delete_phone_log (p_part_no text, p_owner text) AS $body$
DECLARE
ora2pg_rowcount int;
BEGIN

     PERFORM set_config('housekeeping_nocommit.l_error_stage', 'phone_log', false);

     DELETE FROM phone_log
     WHERE  owner = p_owner
     AND    part_no = p_part_no;

     GET DIAGNOSTICS ora2pg_rowcount = ROW_COUNT;


     utl_file.put(l_file, ora2pg_rowcount||',');

   EXCEPTION 
     WHEN others THEN
     
       PERFORM set_config('housekeeping_nocommit.l_err_msg', SUBSTR(sqlerrm,1,200), false);
       RAISE EXCEPTION 'e_delete_error' USING ERRCODE = '50001';
 
   END;

$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;
-- REVOKE ALL ON PROCEDURE hk.housekeeping_nocommit_delete_phone_log (p_part_no text, p_owner text) FROM PUBLIC;
