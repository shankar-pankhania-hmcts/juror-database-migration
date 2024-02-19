-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = "JUROR",public;
\set ON_ERROR_STOP ON

\i ./sources/triggers/ATTENDANCE_UPDATE_trigger.sql
\i ./sources/triggers/COURT_LOCATION_UPDATE_trigger.sql
\i ./sources/triggers/PART_HIST_UPDATE_trigger.sql
\i ./sources/triggers/PHOENIX_DOB_ZIP_trigger.sql
\i ./sources/triggers/PHOENIX_STATUS_trigger.sql
\i ./sources/triggers/PHONE_LOG_UPDATE_trigger.sql
\i ./sources/triggers/POOL_UPDATE_trigger.sql
\i ./sources/triggers/PRINT_FILES_PART_NO_trigger.sql
\i ./sources/triggers/TRG_SP_INSERTUPDATE_trigger.sql
\i ./sources/triggers/UNIQUE_POOL_UPDATE_trigger.sql
\i ./sources/triggers/WELSH_LOCATION_UPDATE_trigger.sql
