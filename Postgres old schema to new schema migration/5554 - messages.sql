/*
 * Task 5554: Develop migration script for the messages table
 * 
 * MESSAGES
 * --------
 * 
 */

TRUNCATE TABLE juror_mod.messages;

WITH rows
AS
(
	insert into juror_mod.messages(juror_number,file_datetime,username,loc_code,phone,email,loc_name,pool_no,subject,message_text,message_id,message_read)
	select DISTINCT 
			m.part_no,
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
	from juror.messages m
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

select count(*) from juror.messages;
select * from juror_mod.messages limit 10;
