-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = "JUROR",public;
\set ON_ERROR_STOP ON

function return_owner (p_schema in varchar2,
                          p_object in varchar2) return varchar2
  as
  begin
   return ' (case  when sys_context(''JUROR_APP'',''OWNER'') is NOT NULL and  owner = sys_context(''JUROR_APP'',''OWNER'') then 1 when sys_context(''JUROR_APP'',''OWNER'') IS NULL then 1 end ) = 1';
end;

