-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.2;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = hk,public;


-- =================================================================================================
-- =================================================================================================
CREATE OR REPLACE PROCEDURE hk.juror_digital_housekeeping_delete_change_log (juror_no text, completed_date timestamp(0), INOUT lb_failed bool) AS $body$
DECLARE
ora2pg_rowcount int;
lc_table_deletions text;
delete_failed text := 'failed delete: ';
lb_failed bool;
BEGIN

    DELETE FROM JUROR_DIGITAL.change_log_view
    WHERE juror_number = juror_no;

    GET DIAGNOSTICS ora2pg_rowcount = ROW_COUNT;


    lc_table_deletions := lc_table_deletions||' TABLE change_log :'|| ora2pg_rowcount::varchar||', ';

EXCEPTION
when others then
  BEGIN
    lc_table_deletions := lc_table_deletions||' TABLE change_log failed :'||SQLERRM::varchar||', ';
    ROLLBACK;
    CALL hk.juror_digital_housekeeping_write_audit(juror_no, completed_date, delete_failed||lc_table_deletions);
    lb_failed := TRUE;
  END;
END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE hk.juror_digital_housekeeping_delete_change_log (juror_no text, completed_date timestamp(0)) FROM PUBLIC;
