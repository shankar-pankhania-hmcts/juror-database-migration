-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = JUROR,public;
\set ON_ERROR_STOP ON

DROP TRIGGER IF EXISTS ATTENDANCE_UPDATE ON ATTENDANCE CASCADE;
CREATE OR REPLACE FUNCTION trigger_fct_attendance_update() RETURNS trigger AS $BODY$
BEGIN
            NEW.LAST_UPDATE := statement_timestamp();
RETURN NEW;
END
$BODY$
 LANGUAGE 'plpgsql' SECURITY DEFINER;
-- REVOKE ALL ON FUNCTION trigger_fct_attendance_update() FROM PUBLIC;

CREATE TRIGGER ATTENDANCE_UPDATE
       BEFORE INSERT OR UPDATE
       ON ATTENDANCE
      FOR EACH ROW
      EXECUTE PROCEDURE trigger_fct_attendance_update();

