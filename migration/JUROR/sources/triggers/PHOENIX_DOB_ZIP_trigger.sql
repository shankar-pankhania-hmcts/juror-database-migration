-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = "JUROR",public;
\set ON_ERROR_STOP ON

DROP TRIGGER IF EXISTS "PHOENIX_DOB_ZIP" ON "POOL" CASCADE;
CREATE OR REPLACE FUNCTION "trigger_fct_phoenix_dob_zip"() RETURNS trigger AS $BODY$
declare
  l_check_on        varchar2(1);
begin
  select nvl(pnc_check_on,'N')
  into   l_check_on
  from   court_location
  where  court_location.loc_code = :new.loc_code;
  if (l_check_on = 'Y' or l_check_on = 'y') then
  begin
    if (nvl(:new.police_check,'^') != 'E' and nvl(:new.police_check, '^') != 'P') then
    begin
        :new.phoenix_date := trunc(sysdate);
    end;
    end if;
  end;
  end if;
exception
  when OTHERS then
      raise_application_error(-20902,'Trigger: phoenix_dob_zip '||SQLERRM||'('||SQLCODE||')');
end
$BODY$
 LANGUAGE 'plpgsql' SECURITY DEFINER;
-- REVOKE ALL ON FUNCTION "trigger_fct_phoenix_dob_zip"() FROM PUBLIC;

CREATE TRIGGER "PHOENIX_DOB_ZIP"
  before update of dob, zip ON "pool" for each row
    
	WHEN ((old.dob is null or old.zip is null) and new.dob is not null and new.zip is not null and (old.status=2 and new.status=2))
	EXECUTE PROCEDURE "trigger_fct_phoenix_dob_zip"();

