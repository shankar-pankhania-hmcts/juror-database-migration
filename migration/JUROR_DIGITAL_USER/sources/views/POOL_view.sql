-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.3;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = juror_digital_user,public;
\set ON_ERROR_STOP ON

CREATE OR REPLACE VIEW pool (owner, part_no, pool_no, poll_number, title, lname, fname, dob, address, address2, address3, address4, address5, address6, zip, h_phone, w_phone, w_ph_local, times_sel, trial_no, juror_no, reg_spc, ret_date, def_date, responded, date_excus, exc_code, acc_exc, date_disq, disq_code, mileage, location, user_edtq, status, notes, no_attendances, is_active, no_def_pos, no_attended, no_fta, no_awol, pool_seq, edit_tag, pool_type, loc_code, next_date, on_call, perm_disqual, pay_county_emp, pay_expenses, spec_need, spec_need_msg, smart_card, amt_spent, completion_flag, completion_date, sort_code, bank_acct_name, bank_acct_no, bldg_soc_roll_no, was_deferred, id_checked, postpone, welsh, paid_cash, travel_time, scan_code, financial_loss, police_check, last_update, read_only, summons_file, reminder_sent, phoenix_date, phoenix_checked, m_phone, h_email, contact_preference, notifications, service_comp_comms_status, transfer_date) AS SELECT
    OWNER,
    PART_NO,
    POOL_NO,
    POLL_NUMBER,
    TITLE,
    LNAME,
    FNAME,
    DOB,
    ADDRESS,
    ADDRESS2,
    ADDRESS3,
    ADDRESS4,
    ADDRESS5,
    ADDRESS6,
    ZIP,
    H_PHONE,
    W_PHONE,
    W_PH_LOCAL,
    TIMES_SEL,
    TRIAL_NO,
    JUROR_NO,
    REG_SPC,
    RET_DATE,
    DEF_DATE,
    RESPONDED,
    DATE_EXCUS,
    EXC_CODE,
    ACC_EXC,
    DATE_DISQ,
    DISQ_CODE,
    MILEAGE,
    LOCATION,
    USER_EDTQ,
    STATUS,
    NOTES,
    NO_ATTENDANCES,
    IS_ACTIVE,
    NO_DEF_POS,
    NO_ATTENDED,
    NO_FTA,
    NO_AWOL,
    POOL_SEQ,
    EDIT_TAG,
    POOL_TYPE,
    LOC_CODE,
    NEXT_DATE,
    ON_CALL,
    PERM_DISQUAL,
    PAY_COUNTY_EMP,
    PAY_EXPENSES,
    SPEC_NEED,
    SPEC_NEED_MSG,
    SMART_CARD,
    AMT_SPENT,
    COMPLETION_FLAG,
    COMPLETION_DATE,
    SORT_CODE,
    BANK_ACCT_NAME,
    BANK_ACCT_NO,
    BLDG_SOC_ROLL_NO,
    WAS_DEFERRED,
    ID_CHECKED,
    POSTPONE,
    WELSH,
    PAID_CASH,
    TRAVEL_TIME,
    SCAN_CODE,
    FINANCIAL_LOSS,
    POLICE_CHECK,
    LAST_UPDATE,
    READ_ONLY,
    SUMMONS_FILE,
    REMINDER_SENT,
    PHOENIX_DATE,
    PHOENIX_CHECKED,
    M_PHONE,
    H_EMAIL,
    CONTACT_PREFERENCE,
    NOTIFICATIONS,
    SERVICE_COMP_COMMS_STATUS,
    TRANSFER_DATE
  FROM JUROR.POOL p
  WHERE p.OWNER = '400' AND p.IS_ACTIVE = 'Y';

