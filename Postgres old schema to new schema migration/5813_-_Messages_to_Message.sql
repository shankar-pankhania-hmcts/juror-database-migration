/*
 * Task 5813: Develop migration script(s) for the messages table
 * 
 * MESSAGES
 * --------
 * 
 * 		Should column part_no be renamed to juror_number?
 * 
 */

TRUNCATE TABLE juror_mod.message;

WITH ROWS
AS
(
	INSERT INTO juror_mod.message(part_no,file_datetime,username,loc_code,phone,email,loc_name,pool_no,subject,message_text,message_id,message_read)
	SELECT  m.part_no,
			m.file_datetime,
			m.username,
			m.loc_code,
			m.phone,
			m.email,
			m.loc_name,
			m.pool_no,
			m.subject,
			m.message_text,
			m.message_id,
			m.message_read
	FROM juror.messages m
	RETURNING 1
)
SELECT COUNT(*) FROM ROWS;  -- ROWS UPDATED

-- verify results
SELECT count(*) FROM juror.messages;
SELECT * FROM juror_mod.message limit 10;

