-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.2;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = hk,public;


   -----------
   --
   -----------
   


CREATE OR REPLACE PROCEDURE hk.housekeeping_close_log () AS $body$
BEGIN

     utl_file.fclose(l_file);
    
   EXCEPTION 
     WHEN OTHERS THEN
      
       -- error return code
         RAISE e_log_error;

   END;

$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;
-- REVOKE ALL ON PROCEDURE hk.housekeeping_close_log () FROM PUBLIC;
