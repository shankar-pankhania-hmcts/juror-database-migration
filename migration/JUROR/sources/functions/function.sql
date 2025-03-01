-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = "JUROR",public;
\set ON_ERROR_STOP ON

\i ./sources/functions/ARAMIS_INVOICE_NUMBER_NEXTVAL_function.sql
\i ./sources/functions/ARAMIS_UNIQUE_ID_NEXTVAL_function.sql
\i ./sources/functions/ATTEND_AUDIT_NUMBER_NEXTVAL_function.sql
\i ./sources/functions/AUDIT_NUMBER_NEXTVAL_function.sql
\i ./sources/functions/BUREAU_ONLY_function.sql
\i ./sources/functions/GET_POOL_COMMENTS_function.sql
\i ./sources/functions/GET_VOTERS_function.sql
\i ./sources/functions/LOCAL_PART_NO_NEXTVAL_function.sql
\i ./sources/functions/RESTRICT_COURT_function.sql
\i ./sources/functions/RETURN_OWNER_function.sql
\i ./sources/functions/SET_UP_VOTERS_function.sql
