/*
 * Task: 6150 - Develop migration script(s) to migrate the POSTPONE_LETT table (court data)
 * 
 */

WITH rows
AS
(
	UPDATE juror_mod.juror_history
	SET other_info_date = l.other_information_date
	FROM (
			SELECT  pl.part_no,
					pl.date_postpone as other_information_date,
					pl.date_printed
			FROM Juror.postpone_lett pl
			WHERE pl.date_printed is not null
			AND pl.owner != '400'
	) as l
	WHERE juror_mod.juror_history.juror_number = l.part_no
	AND juror_mod.juror_history.date_created = l.date_printed
	AND juror_mod.juror_history.history_code = 'RPST'
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/*
 * Verify results
 */
select count(*) 
FROM Juror.postpone_lett pl
join juror_mod.juror_history jh
on juror_number = pl.part_no
AND jh.date_created = pl.date_printed
AND jh.history_code = 'RPST'
WHERE pl.date_printed is not null 
AND pl.owner != '400';
