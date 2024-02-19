/*
 * Task 5514: Develop migration script for the Accused table
 * 
 * ACCUSED
 * -------
 * 
 */

truncate table juror_mod.accused;

WITH rows
AS
(
	insert into juror_mod.accused(owner,trial_no,lname,fname)
	select distinct 
			a.owner,
			a.trial_no,
			a.lname,
			a.fname
	from juror.accused a
	RETURNING 1
 )
select COUNT(*) from rows;  -- rows updated

-- verify results
select count(*) from juror.accused;
select * from juror_mod.accused limit 10;
