-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;


--
-- dblink wrapper to call function phoenix_write_error as an autonomous transaction
--
CREATE EXTENSION IF NOT EXISTS dblink;

CREATE OR REPLACE PROCEDURE phoenix_write_error (p_info text) AS $body$
DECLARE
	-- Change this to reflect the dblink connection string
	v_conn_str  text := format('port=%s dbname=%s user=%s', current_setting('port'), current_database(), current_user);
	v_query     text;

BEGIN
	v_query := 'CALL phoenix_write_error_atx ( ' || quote_nullable(p_info) || ' )';
	PERFORM * FROM dblink(v_conn_str, v_query) AS p (ret boolean);

END;
$body$ LANGUAGE plpgsql SECURITY DEFINER;




CREATE OR REPLACE PROCEDURE phoenix_write_error_atx (p_info text) AS $body$
BEGIN
    INSERT INTO ERROR_LOG(job, error_info) values (lc_Job_Type, p_info);
	 commit;
END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE phoenix_write_error (p_info text) FROM PUBLIC; -- REVOKE ALL ON PROCEDURE phoenix_write_error_atx (p_info text) FROM PUBLIC;
