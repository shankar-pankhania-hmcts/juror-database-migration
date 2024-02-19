-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = JUROR,public;
--\set ON_ERROR_STOP ON

CREATE USER JUROR_DIGITAL_USER WITH PASSWORD 'postgres' LOGIN;
CREATE USER JUROR_DIGITAL WITH PASSWORD 'postgres' LOGIN;

GRANT ALL ON SCHEMA JUROR TO JUROR;
REVOKE ALL ON SCHEMA JUROR FROM PUBLIC;
GRANT USAGE ON SCHEMA JUROR TO JUROR_DIGITAL_USER;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA JUROR TO JUROR_DIGITAL_USER;

GRANT ALL
ON ALL TABLES IN SCHEMA JUROR 
TO JUROR;

GRANT ALL
ON ALL SEQUENCES IN SCHEMA JUROR 
TO JUROR;

GRANT ALL
ON ALL TABLES IN SCHEMA JUROR 
TO system;

GRANT ALL
ON ALL SEQUENCES IN SCHEMA JUROR 
TO system;

-- Set priviledge on PACKAGE BODY COPY_HISTORY
ALTER SCHEMA COPY_HISTORY OWNER TO JUROR;
GRANT ALL ON SCHEMA COPY_HISTORY TO JUROR;
REVOKE ALL ON SCHEMA COPY_HISTORY FROM PUBLIC;
GRANT USAGE ON SCHEMA COPY_HISTORY TO JUROR_DIGITAL_USER;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA COPY_HISTORY TO JUROR_DIGITAL_USER;

-- Set priviledge on PACKAGE BODY POOL_REQUEST_TRANSFER
ALTER SCHEMA POOL_REQUEST_TRANSFER OWNER TO JUROR;
GRANT ALL ON SCHEMA POOL_REQUEST_TRANSFER TO JUROR;
REVOKE ALL ON SCHEMA POOL_REQUEST_TRANSFER FROM PUBLIC;
GRANT USAGE ON SCHEMA POOL_REQUEST_TRANSFER TO JUROR_DIGITAL_USER;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA POOL_REQUEST_TRANSFER TO JUROR_DIGITAL_USER;

-- Set priviledge on SEQUENCE DATA_FILE_NO
ALTER SEQUENCE DATA_FILE_NO OWNER TO JUROR;
GRANT ALL ON SEQUENCE DATA_FILE_NO TO JUROR;
REVOKE ALL ON SEQUENCE DATA_FILE_NO FROM PUBLIC;
GRANT SELECT ON SEQUENCE DATA_FILE_NO TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE CERT_LETT
ALTER TABLE JUROR.CERT_LETT OWNER TO JUROR;
GRANT ALL ON  JUROR.CERT_LETT TO JUROR;
REVOKE ALL ON JUROR.CERT_LETT FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.CERT_LETT TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE CORONER_POOL
ALTER TABLE JUROR.CORONER_POOL OWNER TO JUROR;
GRANT ALL ON  JUROR.CORONER_POOL TO JUROR;
REVOKE ALL ON JUROR.CORONER_POOL FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.CORONER_POOL TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE CORONER_POOL_DETAIL
ALTER TABLE JUROR.CORONER_POOL_DETAIL OWNER TO JUROR;
GRANT ALL ON  JUROR.CORONER_POOL_DETAIL TO JUROR;
REVOKE ALL ON JUROR.CORONER_POOL_DETAIL FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.CORONER_POOL_DETAIL TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE COURT_CATCHMENT_AREA
ALTER TABLE JUROR.COURT_CATCHMENT_AREA OWNER TO JUROR;
GRANT ALL ON  JUROR.COURT_CATCHMENT_AREA TO JUROR;
REVOKE ALL ON JUROR.COURT_CATCHMENT_AREA FROM PUBLIC;
GRANT SELECT ON JUROR.COURT_CATCHMENT_AREA TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE COURT_LOCATION
ALTER TABLE JUROR.COURT_LOCATION OWNER TO JUROR;
GRANT ALL ON  JUROR.COURT_LOCATION TO JUROR;
REVOKE ALL ON JUROR.COURT_LOCATION FROM PUBLIC;
GRANT SELECT ON JUROR.COURT_LOCATION TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE DEF_LETT
ALTER TABLE JUROR.DEF_LETT OWNER TO JUROR;
GRANT ALL ON  JUROR.DEF_LETT TO JUROR;
REVOKE ALL ON JUROR.DEF_LETT FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.DEF_LETT TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE DISQ_LETT
ALTER TABLE JUROR.DISQ_LETT OWNER TO JUROR;
GRANT ALL ON  JUROR.DISQ_LETT TO JUROR;
REVOKE ALL ON JUROR.DISQ_LETT FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.DISQ_LETT TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE ERROR_LOG
ALTER TABLE JUROR.ERROR_LOG OWNER TO JUROR;
GRANT ALL ON  JUROR.ERROR_LOG TO JUROR WITH GRANT OPTION;
REVOKE ALL ON JUROR.ERROR_LOG FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE,DELETE ON JUROR.ERROR_LOG TO JUROR_DIGITAL_USER WITH GRANT OPTION;

-- Set priviledge on TABLE EXC_CODE
ALTER TABLE JUROR.EXC_CODE OWNER TO JUROR;
GRANT ALL ON  JUROR.EXC_CODE TO JUROR;
REVOKE ALL ON JUROR.EXC_CODE FROM PUBLIC;
GRANT SELECT ON JUROR.EXC_CODE TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE EXC_DENIED_LETT
ALTER TABLE JUROR.EXC_DENIED_LETT OWNER TO JUROR;
GRANT ALL ON  JUROR.EXC_DENIED_LETT TO JUROR;
REVOKE ALL ON JUROR.EXC_DENIED_LETT FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.EXC_DENIED_LETT TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE EXC_LETT
ALTER TABLE JUROR.EXC_LETT OWNER TO JUROR;
GRANT ALL ON  JUROR.EXC_LETT TO JUROR;
REVOKE ALL ON JUROR.EXC_LETT FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.EXC_LETT TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE MESSAGES
ALTER TABLE JUROR.MESSAGES OWNER TO JUROR;
GRANT ALL ON  JUROR.MESSAGES TO JUROR;
REVOKE ALL ON JUROR.MESSAGES FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE,DELETE ON JUROR.MESSAGES TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE PART_AMENDMENTS
ALTER TABLE JUROR.PART_AMENDMENTS OWNER TO JUROR;
GRANT ALL ON  JUROR.PART_AMENDMENTS TO JUROR;
REVOKE ALL ON JUROR.PART_AMENDMENTS FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.PART_AMENDMENTS TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE PART_HIST
ALTER TABLE JUROR.PART_HIST OWNER TO JUROR;
GRANT ALL ON  JUROR.PART_HIST TO JUROR;
REVOKE ALL ON JUROR.PART_HIST FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.PART_HIST TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE PASSWORD
ALTER TABLE JUROR.PASSWORD OWNER TO JUROR;
GRANT ALL ON  JUROR.PASSWORD TO JUROR;
REVOKE ALL ON JUROR.PASSWORD FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.PASSWORD TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE PHONE_LOG
ALTER TABLE JUROR.PHONE_LOG OWNER TO JUROR;
GRANT ALL ON  JUROR.PHONE_LOG TO JUROR;
REVOKE ALL ON JUROR.PHONE_LOG FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.PHONE_LOG TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE POOL
ALTER TABLE JUROR.POOL OWNER TO JUROR;
GRANT ALL ON  JUROR.POOL TO JUROR;
REVOKE ALL ON JUROR.POOL FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.POOL TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE POOL_HIST
ALTER TABLE JUROR.POOL_HIST OWNER TO JUROR;
GRANT ALL ON  JUROR.POOL_HIST TO JUROR;
REVOKE ALL ON JUROR.POOL_HIST FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.POOL_HIST TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE PRINT_FILES
ALTER TABLE JUROR.PRINT_FILES OWNER TO JUROR;
GRANT ALL ON  JUROR.PRINT_FILES TO JUROR WITH GRANT OPTION;
REVOKE ALL ON JUROR.PRINT_FILES FROM PUBLIC;
GRANT SELECT ON JUROR.PRINT_FILES TO JUROR_DIGITAL WITH GRANT OPTION;
GRANT SELECT,INSERT,UPDATE ON JUROR.PRINT_FILES TO JUROR_DIGITAL_USER WITH GRANT OPTION;

-- Set priviledge on TABLE REQUEST_LETT
ALTER TABLE JUROR.REQUEST_LETT OWNER TO JUROR;
GRANT ALL ON  JUROR.REQUEST_LETT TO JUROR;
REVOKE ALL ON JUROR.REQUEST_LETT FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.REQUEST_LETT TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE SYSTEM_PARAMETER
ALTER TABLE JUROR.SYSTEM_PARAMETER OWNER TO JUROR;
GRANT ALL ON  JUROR.SYSTEM_PARAMETER TO JUROR;
REVOKE ALL ON JUROR.SYSTEM_PARAMETER FROM PUBLIC;
GRANT SELECT,INSERT,UPDATE ON JUROR.SYSTEM_PARAMETER TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE T_PHONE
ALTER TABLE JUROR.T_PHONE OWNER TO JUROR;
GRANT ALL ON  JUROR.T_PHONE TO JUROR;
REVOKE ALL ON JUROR.T_PHONE FROM PUBLIC;
GRANT SELECT ON JUROR.T_PHONE TO JUROR_DIGITAL_USER;

-- Set priviledge on TABLE T_SPECIAL
ALTER TABLE JUROR.T_SPECIAL OWNER TO JUROR;
GRANT ALL ON  JUROR.T_SPECIAL TO JUROR;
REVOKE ALL ON JUROR.T_SPECIAL FROM PUBLIC;
GRANT SELECT ON JUROR.T_SPECIAL TO JUROR_DIGITAL_USER;