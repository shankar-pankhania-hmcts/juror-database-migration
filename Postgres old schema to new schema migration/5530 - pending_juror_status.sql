/*
 * Task 5530: Develop migration script for the pending_juror_status table
 * 
 * PENDING_JUROR_STATUS
 * --------------------
 * 
 */

ALTER TABLE juror_mod.pending_juror
	DROP constraint IF EXISTS pending_juror_status_fk;

TRUNCATE TABLE juror_mod.pending_juror_status;

WITH rows
AS
(
	insert into juror_mod.pending_juror_status(code,description)
	select distinct
			ms.code,
			ms.description
	from juror.manuals_status ms
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

ALTER TABLE juror_mod.pending_juror 
	ADD constraint pending_juror_status_fk FOREIGN KEY (status) REFERENCES juror.manuals_status(code) NOT VALID;

select count(*) from juror.manuals_status;
select * from juror_mod.pending_juror_status limit 10;
