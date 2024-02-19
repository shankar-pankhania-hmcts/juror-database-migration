/*
 * Task 5532: Develop migration script for the trial table
 * 
 * TRIAL
 * -----
 * 
 * NB: juror_mod.courtroom needs populating prior to running this script in order to identify the ID value of the courtroom
 * 
 * May need to recheck the values of column other_information in Oracle to ensure checks to extract the Trial Number cover all scenarios
 * 
 */

ALTER TABLE juror_mod.trial 
	DROP CONSTRAINT IF EXISTS trial_judge_fk;

ALTER TABLE juror_mod.trial 
	DROP CONSTRAINT IF EXISTS trial_court_loc_fk;

TRUNCATE TABLE juror_mod.juror_trial;
TRUNCATE TABLE juror_mod.trial;

create temporary table IF not exists last_location AS (
	SELECT DISTINCT
			ph.owner,
			CASE 
				WHEN position('.' in ph.other_information) > 0 -- Trial_no after decimal point in description
					THEN RIGHT(ph.other_information,position('.' in REVERSE(ph.other_information))-1)
					ELSE ph.other_information
			END as trial_no,
			ph.pool_no,
			substring(ph.pool_no,1,3) as loc_code,
			ph.date_part,
			RANK() OVER(PARTITION BY substring(ph.pool_no,1,3),
			CASE 
				WHEN position('.' in ph.other_information) > 0 -- Trial_no after decimal point in description
					THEN RIGHT(ph.other_information,position('.' in REVERSE(ph.other_information))-1)
					ELSE ph.other_information
			END
			ORDER BY ph.date_part DESC) as ranking
	FROM juror.part_hist ph
	WHERE UPPER(ph.history_code) in ('VCRE','VADD')
);

WITH trial_rows AS (
	INSERT INTO juror_mod.trial(trial_number,loc_code,description,courtroom,judge,trial_type,trial_start_date,trial_end_date,anonymous)
	SELECT DISTINCT 
			t.trial_no,
			ll.loc_code,
			t.descript,
			c.id as courtroom,
			j.id as judge,
			t.t_type,
			t.trial_dte,
			t.trial_end_date,
			CASE UPPER(t.anonymous)
				WHEN 'Y'
					THEN true
					ELSE false
			END as anonymous
	FROM juror.trial t
	JOIN juror_mod.courtroom c 
	ON t.room_no = c.room_number 
	AND t.owner = c.owner
	JOIN juror_mod.judge j 
	ON t.judge = j.code 
	AND t.owner = j.owner
	JOIN last_location ll	-- use inner join to ensure the loc_code is set: this means if blank or no match then the record will be missed
	ON t.trial_no = ll.trial_no
	AND t.owner = ll.owner
	AND ll.ranking = 1
	RETURNING 1
)
SELECT COUNT(*) FROM trial_rows;  -- rows inserted

ALTER TABLE juror_mod.trial 
	ADD CONSTRAINT trial_judge_fk FOREIGN KEY (judge) REFERENCES juror_mod.judge(id) NOT VALID; 

ALTER TABLE juror_mod.trial 
	ADD CONSTRAINT trial_court_loc_fk FOREIGN KEY (loc_code) REFERENCES juror_mod.court_location(loc_code) NOT VALID;

select count(*) from juror.trial;  -- total rows in hertiage schema
SELECT COUNT(*)	-- missing link to trial number from part history
FROM juror.trial t
LEFT JOIN 	(
				SELECT DISTINCT
						CASE 
							WHEN position('.' in ph.other_information) > 0 -- Trial_no after decimal point in description
								THEN RIGHT(ph.other_information,position('.' in REVERSE(ph.other_information))-1)
								ELSE ph.other_information
						END as trial_no,
						ph.owner
				FROM juror.part_hist ph
				WHERE UPPER(ph.history_code) in ('VCRE','VADD')
			) ph
ON t.trial_no = ph.trial_no
AND t."owner" = ph.owner
WHERE ph.trial_no is null;
select * from juror_mod.trial limit 10;

/*
 * Task 5531: Develop migration script for the juror_trial table
 * 
 * JUROR_TRIAL
 * -----------
 * 
 */

-- clear the table
TRUNCATE TABLE juror_mod.juror_trial;

-- migrate data from Panel
WITH panel_rows AS
(
	insert into juror_mod.juror_trial(loc_code,juror_number,trial_number,pool_number,rand_number,date_selected,result,completed)
	select distinct
			ll.loc_code,
			p.part_no,
			p.trial_no,
			ll.pool_no,
			p.rand_no,
			p.date_selected,
			p.result,
			CASE UPPER(p.complete)
				WHEN 'Y'
					THEN true
					ELSE false
			END
	from juror.panel p
	JOIN last_location ll	-- use inner join to ensure the loc_code is set: this means if blank or no match then the record will be missed
	on p.trial_no = ll.trial_no
	AND p.owner = ll.owner
	AND ll.ranking = 1
	RETURNING 1
)
SELECT COUNT(*) FROM panel_rows;  -- rows updated

-- verification checks
select count(*) from juror.panel;
select * from juror_mod.juror_trial limit 10;
