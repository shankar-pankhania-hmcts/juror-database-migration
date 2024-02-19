-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = "JUROR",public;
\set ON_ERROR_STOP ON

FUNCTION ARAMIS_INVOICE_NUMBER_NEXTVAL(p_Owner varchar2 default sys_context('JUROR_APP','OWNER'))
 RETURN NUMBER IS
 pragma autonomous_transaction;
 id NUMBER;
BEGIN
 execute immediate 'select ARAMIS_INVOICE_NUMBER_'||p_owner||'.nextval from dual ' into id;
 return id;
END ARAMIS_INVOICE_NUMBER_NEXTVAL;

