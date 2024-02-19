/*
 * Task 5551: Develop migration script for the utilisation_stats table
 * 
 * UTILISATION_STATS
 * -----------------
 * 
 */

ALTER table juror_mod.utilisation_stats
	DROP CONSTRAINT IF EXISTS utilisation_stats_fk;

   
TRUNCATE TABLE juror_mod.utilisation_stats;

WITH rows
AS
(
	insert into juror_mod.utilisation_stats(owner,month_start,loc_code,available_days,attendance_days,sitting_days,no_trials,last_update)
	select DISTINCT 
			a.owner,
			a.month_start,
			a.loc_code,
			a.available_days,
			a.attendance_days,
			a.sitting_days,
			a.no_trials,
			a.last_update
	from juror.attendance a
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

ALTER table juror_mod.utilisation_stats
	ADD CONSTRAINT utilisation_stats_fk FOREIGN KEY (loc_code) REFERENCES juror_mod.court_location(loc_code) NOT VALID;

select count(*) from juror.attendance;
select * from juror_mod.utilisation_stats limit 10;
