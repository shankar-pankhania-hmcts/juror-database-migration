-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.4;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = juror_digital,public;
--\set ON_ERROR_STOP ON

CREATE SCHEMA IF NOT EXISTS juror_digital;
CREATE SEQUENCE change_log_item_seq INCREMENT 1 MINVALUE 0 NO MAXVALUE START 1000;
CREATE SEQUENCE change_log_seq INCREMENT 1 MINVALUE 0 NO MAXVALUE START 1000;
CREATE SEQUENCE cjs_employment_seq INCREMENT 1 MINVALUE 0 NO MAXVALUE START 1000;
CREATE SEQUENCE spec_need_seq INCREMENT 1 MINVALUE 0 NO MAXVALUE START 1000;
