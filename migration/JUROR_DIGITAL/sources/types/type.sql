-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.4;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = juror_digital,public;
\set ON_ERROR_STOP ON

DROP TYPE VOTERSROWIDTYPE;
DROP TYPE VOTERSROWIDTABLE;

CREATE SCHEMA IF NOT EXISTS juror_digital;

CREATE TYPE               VOTERSROWIDTYPE as object(ROW_ID varchar2(30));
CREATE TYPE               VOTERSROWIDTABLE as table of VOTERSROWIDTYPE;


