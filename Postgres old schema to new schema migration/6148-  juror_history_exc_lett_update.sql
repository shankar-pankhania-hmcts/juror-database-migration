/*
 * Task: 6148 - Develop migration script(s) to migrate the EXC_LETT table (court data)
 * 
 */

WITH rows
AS
(
	UPDATE juror_mod.juror_history
	SET other_info_date = l.other_information_date,
		other_info_reference = l.other_information_reference
	FROM (
			SELECT  el.part_no,
					el.date_excused as other_information_date,
					el.exc_code as other_information_reference,
					el.date_printed
			FROM Juror.exc_lett el
			WHERE el.date_printed is not null
			AND el.owner != '400'
	) as l
	WHERE juror_mod.juror_history.juror_number = l.part_no
	AND juror_mod.juror_history.date_created = l.date_printed
	AND juror_mod.juror_history.history_code = 'REXC'
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/*
 * Verify results
 */
select count(*) 
FROM Juror.exc_lett el
join juror_mod.juror_history jh
on jh.juror_number = el.part_no
and jh.date_created = el.date_printed
and jh.history_code = 'REXC'
WHERE el.date_printed is not null 
AND el.owner != '400';
