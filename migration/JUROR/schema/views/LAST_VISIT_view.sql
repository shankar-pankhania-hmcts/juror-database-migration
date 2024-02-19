-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = JUROR,public;
\set ON_ERROR_STOP ON

CREATE OR REPLACE VIEW LAST_VISIT (ATT_DATE, PART_NO) AS select max(ATT_DATE) att_date, PART_NO from APPEARANCES
where OWNER = current_setting('JUROR_APP.OWNER', true)
group by PART_NO;

