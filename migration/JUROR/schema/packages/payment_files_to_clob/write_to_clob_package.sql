-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;


/***********************************************************************
* PROCEDURE write_to_clob
*
* 26/2/15 Strip out CRLF (end of line) and pipe characters.
*         Replacing with space to preserve fixed width columns
*
***********************************************************************/
CREATE OR REPLACE PROCEDURE payment_files_to_clob_write_to_clob (p_creation_date timestamp(0), p_header text, p_file_name text) AS $body$
DECLARE

c_extract CURSOR FOR SELECT LOC_CODE,
			UNIQUE_ID,
  			CREATION_DATE,
  			EXPENSE_TOTAL,
			PART_INVOICE,
  			BANK_SORT_CODE,
  			replace(replace(replace(BANK_AC_NAME,'|',' '),chr(10),' '),chr(13),' ') BANK_AC_NAME,
  			replace(replace(replace(BANK_AC_NUMBER,'|',' '),chr(10),' '),chr(13),' ') BANK_AC_NUMBER,
  			replace(replace(replace(BUILD_SOC_NUMBER,'|',' '),chr(10),' '),chr(13),' ') BUILD_SOC_NUMBER,
  			replace(replace(replace(ADDRESS_LINE1,'|',' '),chr(10),' '),chr(13),' ') ADDRESS_LINE1,
  			replace(replace(replace(ADDRESS_LINE2,'|',' '),chr(10),' '),chr(13),' ') ADDRESS_LINE2,
  			replace(replace(replace(ADDRESS_LINE3,'|',' '),chr(10),' '),chr(13),' ') ADDRESS_LINE3,
  			replace(replace(replace(ADDRESS_LINE4,'|',' '),chr(10),' '),chr(13),' ') ADDRESS_LINE4,
  			replace(replace(replace(ADDRESS_LINE5,'|',' '),chr(10),' '),chr(13),' ') ADDRESS_LINE5,
  			replace(replace(replace(POSTCODE,'|',' '),chr(10),' '),chr(13),' ') POSTCODE,
  			ARAMIS_AUTH_CODE,
  			replace(replace(replace(NAME,'|',' '),chr(10),' '),chr(13),' ') NAME,
  			LOC_COST_CENTRE,
  			TRAVEL_TOTAL,
  			SUB_TOTAL,
			FLOSS_TOTAL,
  			SUB_DATE
			FROM ARAMIS_PAYMENTS
			WHERE date_trunc('day', CREATION_DATE) = p_creation_date;

out_rec			varchar(450);
out_rec2		varchar(450);
out_rec3		varchar(450);

c_lob text;
i ARAMIS_PAYMENTS%rowtype;
-- TODO take attributes from cursor and declare variables to copy into for the fetch statement
-- TODO then concat c_lob using ||

BEGIN
	-- Write header line into CLOB
	insert into content_store(request_id, document_id, file_type, data) values (nextval('content_store_seq'),
																	p_File_Name,
																	'PAYMENT' ,
																	NULL ) returning data into c_lob;
	c_lob := p_header || chr(10);
	OPEN c_extract;
	LOOP
		FETCH c_extract into i;
		out_rec := i.loc_code || i.unique_id || '|' || to_char(i.creation_date,'DD-Mon-YYYY') || '|' || lpad(to_char(i.expense_total,'9999990.90'),11) || '|' || rpad(i.loc_code || i.part_invoice,50) || '|' || to_char(i.creation_date,'DD-Mon-YYYY') || '|' || i.bank_sort_code || '|' || rpad(i.bank_ac_name,18) || '|' || rpad(i.bank_ac_number,8) || '|' || rpad(i.build_soc_number,18);
		out_rec2 := '|' || rpad(i.address_line1,35) || '|' || rpad(i.address_line2,35) || '|' || rpad(i.address_line3,35) || '|' || rpad(i.address_line4,35);

		IF i.travel_total IS NOT NULL THEN
			out_rec3 := '|' || rpad(i.address_line5,35) || '|' || rpad(i.postcode,20) || '|' || i.aramis_auth_code || '|' || rpad(i.name,50) || '|' || i.loc_cost_centre || '|' || '2' || '|' || lpad(to_char(i.travel_total,'9999990.90'),11) || '|' || to_char(i.sub_date,'DD-Mon-YYYY');
			c_lob := c_lob || (out_rec||out_rec2||out_rec3)||chr(10);
		END IF;
		IF i.sub_total IS NOT NULL THEN
			out_rec3 := '|' || rpad(i.address_line5,35) || '|' || rpad(i.postcode,20) || '|' || i.aramis_auth_code || '|' || rpad(i.name,50) || '|' || i.loc_cost_centre || '|' || '1' || '|' ||lpad(to_char(i.sub_total,'9999990.90'),11) || '|' || to_char(i.sub_date,'DD-Mon-YYYY');
			c_lob := c_lob || (out_rec||out_rec2||out_rec3)||chr(10);
		END IF;
		IF i.floss_total IS NOT NULL THEN
			out_rec3 := '|' || rpad(i.address_line5,35) || '|' || rpad(i.postcode,20) || '|' || i.aramis_auth_code || '|' || rpad(i.name,50) || '|' || i.loc_cost_centre || '|' || '0' || '|' ||lpad(to_char(i.floss_total,'9999990.90'),11) || '|' || to_char(i.sub_date,'DD-Mon-YYYY');
			c_lob := c_lob || (out_rec||out_rec2||out_rec3)||chr(10);
		END IF;
	END LOOP;
	c_lob := c_lob || '****' || chr(10);
END;

$body$
LANGUAGE PLPGSQL
SECURITY DEFINER
;
-- REVOKE ALL ON PROCEDURE payment_files_to_clob_write_to_clob (p_creation_date timestamp(0), p_header text, p_file_name text) FROM PUBLIC;
