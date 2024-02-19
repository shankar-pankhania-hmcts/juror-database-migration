/*
 * Task: 5216
 * 
 * JUROR_HIST
 * ----------
 * 
 * Migrate data from JUROR.PART_HIST into JUROR_MOD.JUROR_HISTORY
 */

/*
 * Disable any foreign keys prior to deleting any previous data in the new schema
 * Note that simply disabling the FK on the table will not have any effect due to system tables permissions 
 * so the only option is to remove and then re-add them.
 * 
 */
ALTER TABLE juror_mod.juror_history 
	DROP CONSTRAINT juror_history_fk;

TRUNCATE juror_mod.juror_history RESTART IDENTITY cascade;

WITH rows AS 
(
	INSERT into juror_mod.juror_history(juror_number,date_created,history_code,user_id,other_information,pool_number)
	SELECT DISTINCT 
			ph.part_no,
			ph.date_part,
			ph.history_code,
			ph.user_id,
			ph.other_information,
			ph.pool_no
	FROM juror.part_hist ph	
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected

-- Enable any foreign keys prior to deleting any previous data in the new schema
ALTER TABLE juror_mod.juror_history 
	ADD CONSTRAINT juror_history_fk FOREIGN KEY (juror_number) REFERENCES juror_mod.juror(juror_number) NOT valid;


-- verify results
WITH rows AS 
(
	SELECT DISTINCT 
			ph.part_no,
			ph.date_part,
			ph.history_code,
			ph.user_id,
			ph.other_information,
			ph.pool_no
	FROM juror.part_hist ph	
)
SELECT count(*) FROM rows; -- return the number of distinct rows 
select count(*) FROM juror_mod.juror_history;
select max(id) FROM juror_mod.juror_history;
select currval('juror_mod.juror_history_id_seq'::regclass);
