/*
 * Task 5522: Develop migration script for the coroner_pool table
 * 
 * coroner_pool
 * ------------
 * 
 */

ALTER TABLE juror_mod.coroner_pool 
	DROP constraint IF EXISTS coroner_pool_loc_code_fk;

ALTER TABLE juror_mod.coroner_pool_detail 
	DROP CONSTRAINT IF EXISTS coroner_pool_detail_pool_no_fk;

TRUNCATE TABLE juror_mod.coroner_pool;

WITH rows
AS
(
	insert into juror_mod.coroner_pool(cor_pool_no,cor_name,cor_court_loc,cor_request_dt,cor_service_dt,cor_no_requested)
	select DISTINCT
		cp.cor_pool_no,
		cp.cor_name,
		cp.cor_court_loc,
		cp.cor_request_dt,
		cp.cor_service_dt,
		cp.cor_no_requested
	from juror.coroner_pool cp
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

ALTER TABLE juror_mod.coroner_pool 
	ADD CONSTRAINT coroner_pool_loc_code_fk FOREIGN KEY (cor_court_loc) REFERENCES juror_mod.court_location(loc_code) NOT VALID;

ALTER TABLE juror_mod.coroner_pool_detail 
	ADD CONSTRAINT coroner_pool_detail_pool_no_fk FOREIGN KEY (cor_pool_no) REFERENCES juror_mod.coroner_pool(cor_pool_no) NOT VALID;

-- verify results
select COUNT(*) from juror.coroner_pool;
select * from juror_mod.coroner_pool limit 10;
