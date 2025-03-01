-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = JUROR,public;
\set ON_ERROR_STOP ON



--
-- dblink wrapper to call function JUROR.LOCAL_PART_NO_NEXTVAL as an autonomous transaction
--
CREATE EXTENSION IF NOT EXISTS dblink;

CREATE OR REPLACE FUNCTION JUROR.LOCAL_PART_NO_NEXTVAL (p_Owner text default current_setting('JUROR_APP.OWNER', true)) RETURNS bigint AS $body$
DECLARE
	-- Change this to reflect the dblink connection string
	v_conn_str  text := format('port=%s dbname=%s user=%s', current_setting('port'), current_database(), current_user);
	v_query     text;

	v_ret	bigint;
BEGIN
	v_query := 'SELECT * FROM LOCAL_PART_NO_NEXTVAL_atx ( ' || quote_nullable(p_Owner) || ',' || quote_nullable('OWNER') || ' )';
	SELECT * INTO v_ret FROM dblink(v_conn_str, v_query) AS p (ret bigint);
	RETURN v_ret;

END;
$body$ LANGUAGE plpgsql SECURITY DEFINER;




CREATE OR REPLACE FUNCTION JUROR.LOCAL_PART_NO_NEXTVAL_atx (p_Owner text default current_setting('JUROR_APP.OWNER', true)) RETURNS bigint AS $body$
DECLARE
id bigint;

BEGIN
 EXECUTE 'select local_part_no_'||p_owner||'.nextval from dual ' into STRICT id;
 return id;
END;
$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
 STABLE;
-- REVOKE ALL ON FUNCTION JUROR.LOCAL_PART_NO_NEXTVAL (p_Owner text default current_setting('JUROR_APP.OWNER', true)) FROM PUBLIC; -- REVOKE ALL ON FUNCTION JUROR.LOCAL_PART_NO_NEXTVAL_atx (p_Owner text default current_setting('JUROR_APP.OWNER', true)) FROM PUBLIC;

