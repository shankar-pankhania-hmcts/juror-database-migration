/*
 * Task 5529: Develop migration script for the pending_juror table
 * 
 * PENDING_JUROR
 * -------------
 * 
 */

ALTER TABLE juror_mod.pending_juror
	DROP constraint IF EXISTS pending_juror_status_fk;

TRUNCATE TABLE juror_mod.pending_juror;

WITH rows
AS
(
	INSERT INTO juror_mod.pending_juror(juror_number,pool_number,title,last_name,first_name,dob,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode,h_phone,w_phone,w_ph_local,m_phone,h_email,contact_preference,responded,next_date,date_added,mileage,pool_seq,status,is_active,added_by,notes,date_created)
	SELECT DISTINCT
			m.part_no,
			m.pool_no,
			m.title,
			m.lname,
			m.fname,
			m.dob,
			COALESCE(m.address,'') as address1,
			m.address2,
			m.address3,
			COALESCE(m.address4,'') as address4,
			m.address5||CASE WHEN COALESCE(m.address6,'') <> '' THEN ','||m.address6 END AS address5,
			m.zip,
			m.h_phone,
			m.w_phone,
			m.w_ph_local,
			m.m_phone,
			m.h_email,
			m.contact_preference,
			CASE UPPER(m.responded)
				WHEN 'Y'
					THEN true
					ELSE false
			END as responded,
			m.next_date,
			m.date_added,			
			m.mileage,
			m.pool_seq,
			m.pool_status,
			CASE UPPER(m.is_active)
				WHEN 'Y'
					THEN true
					ELSE false
			END as is_active,
			m.added_by,
			m.notes,
			(select MIN(ph.last_update) from juror.part_hist ph where ph.part_no = m.part_no) as date_created  -- take first entry in juror histoery
	FROM juror.manuals m
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

ALTER TABLE juror_mod.pending_juror 
	ADD constraint pending_juror_status_fk FOREIGN KEY (status) REFERENCES juror.manuals_status(code) NOT VALID;

select count(*) from juror.manuals;
select * from juror_mod.pending_juror limit 10;
