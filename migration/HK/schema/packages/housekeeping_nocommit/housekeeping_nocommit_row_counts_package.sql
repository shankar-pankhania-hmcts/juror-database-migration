-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.2;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = hk,public;


   -----------
   --
   -----------   
CREATE OR REPLACE PROCEDURE hk.housekeeping_nocommit_row_counts (p_stage text) AS $body$
BEGIN

        SELECT COUNT(*) INTO STRICT l_part_hist(p_stage)       FROM part_hist;
        SELECT COUNT(*) INTO STRICT l_part_expenses(p_stage)   FROM part_expenses;
        SELECT COUNT(*) INTO STRICT l_audit_report(p_stage)    FROM audit_report;
        SELECT COUNT(*) INTO STRICT l_cert_lett(p_stage)       FROM cert_lett;
        SELECT COUNT(*) INTO STRICT l_disq_lett(p_stage)       FROM disq_lett;
        SELECT COUNT(*) INTO STRICT l_manuals(p_stage)         FROM manuals;
        SELECT COUNT(*) INTO STRICT l_audit_f_report(p_stage)  FROM audit_f_report;
        SELECT COUNT(*) INTO STRICT l_appearances(p_stage)     FROM appearances;
        SELECT COUNT(*) INTO STRICT l_confirm_lett(p_stage)    FROM confirm_lett;
        SELECT COUNT(*) INTO STRICT l_part_amendments(p_stage) FROM part_amendments;
        SELECT COUNT(*) INTO STRICT current_setting('housekeeping_nocommit.l_def_lett')::logs(p_stage)        FROM def_lett;
        SELECT COUNT(*) INTO STRICT current_setting('housekeeping_nocommit.l_def_denied')::logs(p_stage)      FROM def_denied;
        SELECT COUNT(*) INTO STRICT current_setting('housekeeping_nocommit.l_exc_denied_lett')::logs(p_stage) FROM exc_denied_lett;
        SELECT COUNT(*) INTO STRICT current_setting('housekeeping_nocommit.l_postpone_lett')::logs(p_stage)   FROM postpone_lett;
        SELECT COUNT(*) INTO STRICT current_setting('housekeeping_nocommit.l_fta_lett')::logs(p_stage)        FROM fta_lett;
        SELECT COUNT(*) INTO STRICT current_setting('housekeeping_nocommit.l_request_lett')::logs(p_stage)    FROM request_lett;
        SELECT COUNT(*) INTO STRICT current_setting('housekeeping_nocommit.l_phone_log')::logs(p_stage)       FROM phone_log;
        SELECT COUNT(*) INTO STRICT current_setting('housekeeping_nocommit.l_exc_lett')::logs(p_stage)        FROM exc_lett;
        SELECT COUNT(*) INTO STRICT current_setting('housekeeping_nocommit.l_undeliver')::logs(p_stage)       FROM undelivr;
        SELECT COUNT(*) INTO STRICT current_setting('housekeeping_nocommit.l_pool')::logs(p_stage)            FROM pool;
        SELECT COUNT(*) INTO STRICT l_defer_dbf(p_stage)       FROM defer_dbf;

    END;

$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;
-- REVOKE ALL ON PROCEDURE hk.housekeeping_nocommit_row_counts (p_stage text) FROM PUBLIC;
