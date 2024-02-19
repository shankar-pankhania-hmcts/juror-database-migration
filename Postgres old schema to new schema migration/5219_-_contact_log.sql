/*
 * Task: 5219
 * 
 * CONTACT_LOG
 * -----------
 * 
 * Migrate data from JUROR.PHONE_LOG into JUROR_MOD.CONTACT_LOG
 */

/*
 * Disable any foreign keys prior to deleting any previous data in the new schema
 * Note that simply disabling the FK on the table will not have any effect due to system tables permissions 
 * so the only option is to remove and then re-add them.
 * 
 */
ALTER TABLE juror_mod.contact_log 
	DROP CONSTRAINT juror_number_fk;

TRUNCATE juror_mod.contact_log RESTART IDENTITY cascade;

with rows
as
(
 	INSERT into juror_mod.contact_log (juror_number,user_id,start_call,end_call,enquiry_type,notes,last_update)
	SELECT DISTINCT 
			pl.part_no,
			pl.user_id,
			pl.start_call,
			pl.end_call,
			pl.phone_code,
			pl.notes,
			pl.last_update
	FROM juror.phone_log pl
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected

 
-- Enable any foreign keys prior to deleting any previous data in the new schema
ALTER TABLE juror_mod.contact_log 
	ADD CONSTRAINT juror_number_fk FOREIGN KEY (juror_number) REFERENCES juror_mod.juror(juror_number) NOT valid;

-- verify results
select count(*) FROM juror.phone_log;
select * FROM juror_mod.contact_log limit 10;
