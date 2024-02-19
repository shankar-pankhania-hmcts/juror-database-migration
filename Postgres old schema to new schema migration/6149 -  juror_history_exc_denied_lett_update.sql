/*
 * Task: 6149 - Develop migration script(s) to migrate the EXC_DENIED_LETT table (court data)
 * 
 */

WITH rows
AS
(
	UPDATE juror_mod.juror_history
	SET other_info_date = l.other_information_date,
		other_info_reference = l.other_information_reference
	FROM (
			SELECT  edl.part_no,
					edl.date_excused as other_information_date,
					edl.exc_code as other_information_reference,
					edl.date_printed
			FROM Juror.exc_denied_lett edl
			WHERE edl.date_printed is not null
			AND edl.owner != '400'
	) as l
	WHERE juror_mod.juror_history.juror_number = l.part_no
	AND juror_mod.juror_history.date_created = l.date_printed
	AND juror_mod.juror_history.history_code = 'REDL'
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/*
 * Verify results
 */
select count(*) 
FROM Juror.exc_denied_lett edl
join juror_mod.juror_history jh
ON jh.juror_number = edl.part_no
AND jh.date_created = edl.date_printed
AND jh.history_code = 'REDL'
WHERE edl.date_printed is not null 
AND edl.owner != '400';
