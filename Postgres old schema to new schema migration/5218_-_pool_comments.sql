/*
 * Task: 5218
 * 
 * POOL_COMMENTS
 * -------------
 * 
 * Migrate data from JUROR.POOL_COMMENTS into JUROR_MOD.POOL_COMMENTS
 */

/*
 * Disable any foreign keys prior to deleting any previous data in the new schema
 * Note that simply disabling the FK on the table will not have any effect due to system tables permissions 
 * so the only option is to remove and then re-add them.
 * 
 */
ALTER TABLE juror_mod.pool_comments 
	DROP CONSTRAINT pool_comments_pool_no_fk;

TRUNCATE juror_mod.pool_comments RESTART IDENTITY cascade;

with rows
as
(
 	INSERT into juror_mod.pool_comments(pool_no,user_id,last_update,pcomment,no_requested)
	SELECT DISTINCT 
			pc.pool_no,
			pc.user_id,
			pc.last_update,
			pc.pcomment,
			pc.no_requested
	FROM juror.pool_comments pc
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected

-- Enable any foreign keys prior to deleting any previous data in the new schema
ALTER TABLE juror_mod.pool_comments 
	ADD CONSTRAINT pool_comments_pool_no_fk FOREIGN KEY (pool_no) REFERENCES juror_mod.pool(pool_no) not VALID;

-- verify results
with rows
as
(
	SELECT DISTINCT 
			pc.pool_no,
			pc.user_id,
			pc.last_update,
			pc.pcomment,
			pc.no_requested
	FROM juror.pool_comments pc
)
SELECT count(*) FROM rows; -- return the number of rows affected
select * FROM juror_mod.pool_comments limit 10;
