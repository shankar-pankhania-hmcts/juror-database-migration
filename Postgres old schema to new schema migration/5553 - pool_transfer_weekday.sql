/*
 * Task 5553: Develop migration script for the pool_transfer_weekday table
 * 
 * pool_transfer_weekday
 * ---------------------
 * 
 */

TRUNCATE TABLE juror_mod.pool_transfer_weekday;

WITH rows
AS
(
	insert into juror_mod.pool_transfer_weekday(transfer_day,run_day,adjustment)
	select DISTINCT 
			ptw.transfer_day,
			ptw.run_day,
			ptw.adjustment
	from juror.pool_transfer_weekday ptw
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

select count(*) from juror.pool_transfer_weekday;
select * from juror_mod.pool_transfer_weekday limit 10;
