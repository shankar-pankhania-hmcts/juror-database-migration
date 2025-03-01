-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.3;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = juror_digital_user,public;
\set ON_ERROR_STOP ON

CREATE OR REPLACE VIEW def_lett (owner, part_no, date_def, exc_code, printed, date_printed) AS SELECT
    OWNER,
    PART_NO,
    DATE_DEF,
    EXC_CODE,
    PRINTED,
    DATE_PRINTED
  FROM JUROR.DEF_LETT dl
  WHERE dl.OWNER = 400;

