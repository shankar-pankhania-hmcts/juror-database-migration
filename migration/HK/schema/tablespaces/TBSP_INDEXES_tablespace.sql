-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.2;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = hk,public;
\set ON_ERROR_STOP ON

-- Oracle tablespaces export, please edit path to match your filesystem.
-- In PostgreSQl the path must be a directory and is expected to already exists
ALTER INDEX hk_params_pk SET TABLESPACE system;
