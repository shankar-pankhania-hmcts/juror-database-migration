/*
 * Task: 6144 - Develop migration script(s) to migrate the DEF_DENIED table (court data)
 * 
 */

with rows
AS
(
	UPDATE juror_mod.juror_history
	SET other_info_date = l.other_information_date,
		other_info_reference = l.other_information_reference
	FROM (
			SELECT  dd.part_no,
					dd.date_def as other_information_date,
					dd.exc_code as other_information_reference,
					dd.date_printed
			FROM Juror.def_denied dd
			WHERE dd.date_printed is not null
			AND dd.owner != '400'
	) as l
	WHERE juror_mod.juror_history.juror_number = l.part_no
	AND juror_mod.juror_history.date_created = l.date_printed
	AND juror_mod.juror_history.history_code = 'RDDL'
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/*
 * Verify results
 */
select count(*) 
FROM Juror.def_denied dd
join juror_mod.juror_history jh
on 	jh.juror_number = dd.part_no
AND jh.date_created = dd.date_printed
AND jh.history_code = 'RDDL'
WHERE dd.date_printed is not null
AND dd.owner != '400';

