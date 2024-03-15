/* 
 * Task: 5220
 * 
 * JUROR_AUDIT
 * -----------
 * 
 * Migrate data from PART_AMENDMENTS into JUROR_AUDIT
 * 
 * - Build a temporary table to hold addresses in multiple columns rather than a (long) single line
 * - Each line is identified via a comma
 * - Pivot the results of the address columns into one row per ID
 * - Join to addresses CTE to build data to import
 */

/*
 * Handle the comma separated column of PART_AMENDMENTS prior to copying the data in bulk
 * Due to PART_AMENDMENTS storing the address in a single column (comma separated) we need to define a temporary table to hold the address
*/
CREATE TABLE IF NOT EXISTS temp_addresses(ID varchar(200), addressline smallint, address varchar(35));
TRUNCATE TABLE temp_addresses;

-- Build the table by splitting the comma separated string column - note the need to store the line number for each row 
INSERT INTO temp_addresses(ID,addressline,address)
SELECT a.ID, a.addressline, a.address
FROM	( 
			SELECT DISTINCT pa.part_no||pa.edit_date||pa.address as ID, 
					a.nr as addressline,
					ltrim(a.elem) as address
			FROM juror.part_amendments pa
			JOIN lateral unnest(string_to_array(pa.address,',')) WITH ORDINALITY a(elem, nr) on true
			WHERE COALESCE(pa.address,'') <> ''
	 	) a;

CREATE EXTENSION if not exists tablefunc;


ALTER TABLE juror_mod.juror_audit DROP CONSTRAINT IF EXISTS fk_revision_number;

TRUNCATE TABLE juror_mod.juror_audit RESTART IDENTITY CASCADE; 

WITH juror_changes
AS
(
	-- group together rows for the same juror and edit date
	SELECT DISTINCT
			pa.part_no,
			pa.edit_date,
			MAX(pa.title) as title,
			MAX(pa.fname) as fname,
			MAX(pa.lname) as lname,
			MAX(pa.dob) as dob,
			MAX(pa.address) as address,
			MAX(pa.zip) as zip,
			MAX(pa.sort_code) as sort_code,
			MAX(pa.bank_acct_name) as bank_acct_name,
			MAX(pa.bank_acct_no) as bank_acct_no,
			MAX(pa.bldg_soc_roll_no) as bldg_soc_roll_no,
			MAX(p.h_email) as h_email,
			MAX(p.h_phone) as h_phone,
			MAX(p.m_phone) as m_phone,
			MAX(p.w_phone) as w_phone,
			MAX(p.w_ph_local) as w_ph_local,
			MAX(a.address1) as address1,
			MAX(a.address2) as address2,
			MAX(a.address3) as address3,
			MAX(a.address4) as address4,
			MAX(a.address5) as address5
	FROM juror.part_amendments pa
	JOIN juror_mod.juror j
	ON pa.part_no = j.juror_number
	LEFT JOIN (
				-- use a pviot to produce a single row for each part_no for the address columns
				SELECT  id,
						address1,
						address2,
						address3,
						address4,
						address5
				FROM CROSSTAB('SELECT a.ID, a.addressline, a.address FROM temp_addresses a ORDER BY 1,2')
				AS addr_table (ID varchar(200), address1 varchar(35), address2 varchar(35), address3 varchar(35), address4 varchar(35), address5 varchar(35))
			) a
	ON pa.part_no||pa.edit_date||coalesce(pa.address,'') = a.ID
	LEFT JOIN juror.pool p
	ON pa.part_no = p.part_no 
	AND pa.pool_no = p.pool_no
	AND pa.owner = p.owner
	GROUP BY pa.part_no,
			 pa.edit_date
),
rows as (
	SELECT  NEXTVAL('public.rev_info_seq') as revision,
			CASE 
				WHEN RANK() OVER(PARTITION BY a.juror_number ORDER BY a.juror_number asc, a.edit_date) = 1
					THEN 0 -- first insert
					ELSE 1 -- update
			END as rev_type,
			a.edit_date,
			a.juror_number,
			a.title,
			a.fname,
		 	a.lname,
			a.dob,
			a.address_line_1,
			a.address_line_2,
			a.address_line_3,
			a.address_line_4,
			a.address_line_5, 
			a.postcode,
			a.sort_code,
			a.bank_acct_name,
			a.bank_acct_no,
			a.bldg_soc_roll_no,
			a.h_email,
			a.h_phone,
			a.m_phone,
			a.w_phone,
			a.w_ph_local
	FROM (
			SELECT DISTINCT
					jc.part_no as juror_number,
					jc.edit_date as edit_date,
					CASE
							WHEN jc.title IS NULL AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.title IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
								THEN (SELECT jc2.title FROM juror_changes jc2 WHERE jc2.title IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
							WHEN jc.title is NULL
								THEN j.title
								ELSE jc.title
					END AS title,
					CASE
						WHEN jc.fname IS NULL  AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.fname IS NOT NULL AND jc2.edit_date > jc.edit_date  AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.fname FROM juror_changes jc2 WHERE jc2.fname IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
						WHEN jc.fname IS NULL 
							THEN j.first_name
							ELSE jc.fname
					END AS fname,
					CASE
						WHEN jc.lname IS NULL  AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.lname IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.lname FROM juror_changes jc2 WHERE jc2.lname IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
						WHEN jc.lname IS NULL 
							THEN j.last_name
							ELSE jc.lname
					END AS lname,
					CASE
						-- when null or set to 1901-01-01 with later amendments then set to next amendment record - if date is 1901-01-01 then set to NULL
						WHEN coalesce(jc.dob,'1901-01-01') = '1901-01-01' AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.dob IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
							THEN (SELECT CASE WHEN jc2.dob = '1901-01-01' THEN NULL ELSE jc2.dob END FROM juror_changes jc2 WHERE jc2.dob IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
						-- when null or set to 1901-01-01 but no later amendments then set to current juror record
						WHEN coalesce(jc.dob,'1901-01-01') = '1901-01-01' AND NOT EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
							THEN j.dob
						-- otherwise if set to 1901-01-01 then set to null
						WHEN jc.dob = '1901-01-01'
							THEN NULL
							ELSE jc.dob
					END AS dob,
					CASE
						WHEN jc.address1 IS NULL AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.address1 IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.address1 FROM juror_changes jc2 WHERE jc2.address1 IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
						WHEN jc.address1 IS NULL 
							THEN j.address_line_1
							ELSE jc.address1
					END AS address_line_1,
					CASE
						WHEN jc.address2 IS NULL AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.address2 IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.address2 FROM juror_changes jc2 WHERE jc2.address2 IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
						WHEN jc.address2 IS NULL 
							THEN j.address_line_2
							ELSE jc.address2
					END AS address_line_2,
					CASE
						WHEN jc.address3 IS NULL AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.address3 IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.address3 FROM juror_changes jc2 WHERE jc2.address3 IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
						WHEN jc.address3 IS NULL 
							THEN j.address_line_3
							ELSE jc.address3
					END AS address_line_3,
					CASE
						WHEN jc.address4 IS NULL AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.address4 IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.address4 FROM juror_changes jc2 WHERE jc2.address4 IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
						WHEN jc.address4 IS NULL 
							THEN j.address_line_4
							ELSE jc.address4
					END AS address_line_4,
					CASE
						WHEN jc.address5 IS NULL AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.address5 IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.address5 FROM juror_changes jc2 WHERE jc2.address5 IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
						WHEN jc.address5 IS NULL 
							THEN j.address_line_5
							ELSE jc.address5
					END AS address_line_5,
					CASE
						WHEN jc.zip IS NULL  AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.zip IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.zip FROM juror_changes jc2 WHERE jc2.zip IS NOT null AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no LIMIT 1)
						WHEN jc.zip IS NULL 
							THEN j.postcode
							ELSE jc.zip
					END AS postcode,
					CASE
						WHEN jc.sort_code IS NULL AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.sort_code IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.sort_code FROM juror_changes jc2 where  jc2.sort_code IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no limit 1)
						WHEN jc.sort_code IS NULL 
							THEN j.sort_code
							ELSE jc.sort_code
					END AS sort_code,
					CASE
						WHEN jc.bank_acct_name IS NULL AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.bank_acct_name IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.bank_acct_name FROM juror_changes jc2 WHERE jc2.bank_acct_name IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no limit 1)
						WHEN jc.bank_acct_name IS NULL 
							THEN j.bank_acct_name
							else jc.bank_acct_name
					END AS bank_acct_name,
					CASE
						WHEN jc.bank_acct_no IS NULL AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.bank_acct_no IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.bank_acct_no FROM juror_changes jc2 WHERE jc2.bank_acct_no IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no limit 1)
						WHEN jc.bank_acct_no IS NULL 
							THEN j.bank_acct_no
							else jc.bank_acct_no
					END AS bank_acct_no,
					CASE
						WHEN jc.bldg_soc_roll_no IS NULL AND EXISTS(SELECT 1 FROM juror_changes jc2 WHERE jc2.bldg_soc_roll_no IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no)
							THEN (SELECT jc2.bldg_soc_roll_no FROM juror_changes jc2 WHERE jc2.bldg_soc_roll_no IS NOT NULL AND jc2.edit_date > jc.edit_date AND jc2.part_no = jc.part_no limit 1)
						WHEN jc.bldg_soc_roll_no IS NULL 
							THEN j.bldg_soc_roll_no
							ELSE jc.bldg_soc_roll_no
					END AS bldg_soc_roll_no,
					CASE
						WHEN jc.h_email IS NULL 
							THEN j.h_email
							ELSE jc.h_email
					END AS h_email,
					CASE
						WHEN jc.h_phone IS NULL 
							THEN j.h_phone
							ELSE jc.h_phone
					END AS h_phone,
					CASE
						WHEN jc.m_phone IS NULL 
							THEN j.m_phone
							ELSE jc.m_phone
					END AS m_phone,
					CASE
						WHEN jc.w_phone IS NULL 
							THEN j.w_phone
							ELSE jc.w_phone
					END AS w_phone,
					CASE
						WHEN jc.w_ph_local IS NULL 
							THEN j.w_ph_local
							ELSE jc.w_ph_local
					END AS w_ph_local
			FROM juror_changes jc
			JOIN juror_mod.juror j
			ON jc.part_no = j.juror_number
			UNION
			SELECT 	j.juror_number,
					j.last_update as edit_date,
					j.title,
					j.first_name,
					j.last_name,
					j.dob,
					j.address_line_1,
					j.address_line_2,
					j.address_line_3,
					j.address_line_4,
					j.address_line_5,
					j.postcode,
					j.sort_code,
					j.bank_acct_name,
					j.bank_acct_no,
					j.bldg_soc_roll_no,
					j.h_email,
					j.h_phone,
					j.m_phone,
					j.w_phone,
					j.w_ph_local
			FROM juror_mod.juror j
			ORDER BY 1,2
		) a
),
rev_info
AS 
(
	INSERT INTO juror_mod.rev_info(revision_number,revision_timestamp)
	SELECT revision, cast(extract(epoch from edit_date) as integer) 
	FROM rows 
)
-- create the audit records and increment the sequence by merging data with later changes and if none then from juror table where amendment column is null 
INSERT INTO juror_mod.juror_audit (revision,rev_type,juror_number,title,first_name,last_name,dob,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode,h_email,bank_acct_name,bank_acct_no,bldg_soc_roll_no,sort_code,h_phone,m_phone,w_phone,w_ph_local)
SELECT  r.revision,
		r.rev_type,
		r.juror_number,
		r.title,
		r.fname,
	 	r.lname,
		r.dob,
		r.address_line_1,
		r.address_line_2,
		r.address_line_3,
		r.address_line_4,
		r.address_line_5, 
		r.postcode,
		r.sort_code,
		r.bank_acct_name,
		r.bank_acct_no,
		r.bldg_soc_roll_no,
		r.h_email,
		r.h_phone,
		r.m_phone,
		r.w_phone,
		r.w_ph_local
FROM rows r;

-- remove the temporary table
DROP TABLE IF EXISTS temp_addresses;

-- Enable any foreign keys prior to deleting any previous data in the new schema
ALTER TABLE juror_mod.juror_audit ADD CONSTRAINT fk_revision_number FOREIGN KEY (revision) REFERENCES juror_mod.rev_info(revision_number);

-- verify results
WITH rows
AS
(
 	SELECT  pa.part_no,
			pa.edit_date
	FROM juror.part_amendments pa
	GROUP BY pa.part_no,
			 pa.edit_date
)
SELECT COUNT(*) FROM rows;  -- row count for part-amendments per juror & editted date


select max(revision) FROM juror_mod.juror_audit;	-- check last ID value in new table
select last_value from rev_info_seq;				-- check last ID value in sequence table
select ri.*, ja.revision , ja.juror_number, ja.rev_type from  juror_mod.rev_info ri join juror_mod.juror_audit ja on ri.revision_number = ja.revision order by revision_number desc limit 10; -- check the sequence numbers are built and in sync
select * FROM juror_mod.juror_audit limit 10;
