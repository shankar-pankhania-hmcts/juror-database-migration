/*
 * Task: 5217
 * 
 * POOL_HISTORY
 * ------------
 * 
 * Migrate data from JUROR.POOL_HIST into POOL_HIST
 */

/*
 * Disable any foreign keys prior to deleting any previous data in the new schema
 * Note that simply disabling the FK on the table will not have any effect due to system tables permissions 
 * so the only option is to remove and then re-add them.
 * 
 */
ALTER TABLE juror_mod.pool_history 
	DROP CONSTRAINT pool_history_fk;

TRUNCATE TABLE juror_mod.pool_history RESTART IDENTITY cascade;

with rows
as
(
 	INSERT into juror_mod.pool_history(pool_no,history_code,user_id,other_information,history_date)
	SELECT DISTINCT 
			ph.pool_no,
			ph.history_code,
			ph.user_id,
			ph.other_information,
			ph.date_part
	FROM juror.pool_hist ph
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected

-- Enable any foreign keys prior to deleting any previous data in the new schema
ALTER TABLE juror_mod.pool_history 
	ADD CONSTRAINT pool_history_fk FOREIGN KEY (history_code) REFERENCES juror_mod.t_history_code(history_code) not VALID;


-- verify results
select count(*) FROM juror.pool_hist;
select * FROM juror_mod.pool_history limit 10;
