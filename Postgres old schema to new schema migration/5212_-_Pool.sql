/*
 * Task: 5212
 * 
 * POOL
 * ----
 * 
 * Migrate data from JUROR.UNIQUE_POOL into JUROR_MOD.POOL 
 */

/*
 * Disable any foreign keys prior to deleting any previous data in the new schema
 * Note that simply disabling the FK on the table will not have any effect due to system tables permissions 
 * so the only option is to remove and then re-add them.
 * 
 */
ALTER TABLE juror_mod.juror_pool
   DROP CONSTRAINT IF EXISTS juror_pool_pool_no_fk; 

ALTER TABLE juror_mod.pool_comments
   DROP CONSTRAINT IF EXISTS pool_comments_pool_no_fk; 

ALTER TABLE juror_mod.pool_comments 
	DROP CONSTRAINT IF EXISTS pool_comments_fk;
  
      
truncate table juror_mod.pool;

WITH rows 
AS 
(
	insert into juror_mod.pool(owner,pool_no,return_date,no_requested,pool_type,loc_code,new_request,last_update,additional_summons,attend_time,total_no_required)
	SELECT DISTINCT 
			p.owner,
			p.pool_no,
			p.return_date,
			p.no_requested,
			p.pool_type,
			p.loc_code,
			p.new_request,
			p.last_update,
			p.additional_summons,
			p.attend_time,
			0 as total_no_required -- nulls not allowed to set to 0
	FROM juror.unique_pool p
	WHERE read_only = 'N'  -- editable so current record
	RETURNING 1
)
SELECT count(*) FROM rows;

-- Enable any foreign keys prior to deleting any previous data in the new schema
ALTER TABLE juror_mod.juror_pool
   ADD CONSTRAINT juror_pool_pool_no_fk FOREIGN KEY (pool_number) references juror_mod.pool(pool_no) not VALID;

ALTER TABLE juror_mod.pool_comments
   ADD CONSTRAINT pool_comments_pool_no_fk FOREIGN KEY (pool_no) references juror_mod.pool(pool_no) not VALID; 

ALTER TABLE juror_mod.pool_comments 
	ADD CONSTRAINT pool_comments_fk FOREIGN KEY (pool_no) REFERENCES juror_mod.pool(pool_no) not valid;

  
-- verify results
select count(*) FROM juror.unique_pool WHERE read_only = 'N';
select * FROM juror_mod.pool LIMIT 10;
