/*
 * Task: 6137 - Develop migration script(s) to migrate the DEF_LETT table (court data)
 * 
 */

with rows
AS
(
	UPDATE juror_mod.juror_history
	SET other_info_date = l.other_information_date,
		other_info_reference = l.other_information_reference
	FROM (
			SELECT  dl.part_no,
					dl.date_def as other_information_date,
					dl.exc_code as other_information_reference,
					dl.date_printed
			FROM Juror.def_lett dl
			WHERE dl.date_printed is not null
			AND dl.owner != '400'
	) as l
	WHERE juror_mod.juror_history.juror_number = l.part_no
	AND juror_mod.juror_history.date_created = l.date_printed
	AND juror_mod.juror_history.history_code = 'RDEF'
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/*
 * Verify results
 */
SELECT COUNT(*) 
FROM juror_mod.juror_history jh
JOIN Juror.def_lett dl 
ON jh.juror_number = dl.part_no
AND dl.date_printed = jh.date_created
AND dl.owner != '400'
WHERE jh.history_code = 'RDEF';
	