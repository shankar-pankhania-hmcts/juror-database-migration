-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.4;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = juror_digital,public;
\set ON_ERROR_STOP ON

CREATE OR REPLACE VIEW change_log_view (id, juror_number, logged, staff, type, notes, version) AS SELECT
    ID,
    JUROR_NUMBER,
    TIMESTAMP LOGGED,
    STAFF,
    TYPE,
    NOTES,
    VERSION
FROM JUROR_DIGITAL.CHANGE_LOG;

