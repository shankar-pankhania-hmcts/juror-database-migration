-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.4;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = juror_digital,public;
\set ON_ERROR_STOP ON

\i './sources/views/LOC_POSTCODE_TOTALS_VIEW_view.sql'
\i './sources/views/CHANGE_LOG_VIEW_view.sql'
\i './sources/views/ABACCUS_view.sql'
\i './sources/views/SUMMONS_SNAPSHOT_view.sql'
\i './sources/views/MOJ_JUROR_DETAIL_view.sql'

