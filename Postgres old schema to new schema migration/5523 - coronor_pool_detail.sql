/*
 * Task 5523: Develop migration script for the coroner_pool_detail table
 * 
 * coroner_pool_detail
 * -------------------
 * 
 * CLARIFY COLUMNS NAMES FOR PART_NO (JUROR_NUMBER) AND ADDRESSES
 */

ALTER TABLE juror_mod.coroner_pool_detail 
	DROP CONSTRAINT IF EXISTS coroner_pool_detail_pool_no_fk;

TRUNCATE TABLE juror_mod.coroner_pool_detail;

WITH rows
AS
(
	INSERT INTO juror_mod.coroner_pool_detail(cor_pool_no,juror_number,title,first_name,last_name,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode)
	SELECT 	cpd.cor_pool_no,
			cpd.part_no,
			cpd.title,
			cpd.fname,
			cpd.lname,
			cpd.address1,
			cpd.address2,
			cpd.address3,
			cpd.address4,
			cpd.address5||CASE WHEN COALESCE(cpd.address6,'') <> '' THEN ','||cpd.address6 END AS address5,
			cpd.postcode
	FROM juror.coroner_pool_detail cpd
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

ALTER TABLE juror_mod.coroner_pool_detail 
	ADD CONSTRAINT coroner_pool_detail_pool_no_fk FOREIGN KEY (cor_pool_no) REFERENCES juror_mod.coroner_pool(cor_pool_no) NOT VALID;

-- verify results
select COUNT(*) from juror.coroner_pool_detail;
select * from juror_mod.coroner_pool_detail limit 10;
