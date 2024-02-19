/*
 * Task: 6151 - Develop migration script(s) to migrate the FTA_LETT table (court data)
 * 
 */

WITH rows
AS
(
	UPDATE juror_mod.juror_history
	SET other_info_date = l.other_information_date
	FROM (
			SELECT  fl.part_no,
					fl.date_fta as other_information_date,
					fl.date_printed
			FROM Juror.fta_lett fl
			WHERE fl.date_printed is not null
			AND fl.owner != '400'
	) as l
	WHERE juror_mod.juror_history.juror_number = l.part_no
	AND juror_mod.juror_history.date_created = l.date_printed
	AND juror_mod.juror_history.history_code = 'RFTA'
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/*
 * Verify results
 */
select count(*) 
FROM Juror.fta_lett fl
join juror_mod.juror_history jh
on juror_number = fl.part_no
AND jh.date_created = fl.date_printed
AND jh.history_code = 'RFTA'
WHERE fl.date_printed is not null 
AND fl.owner != '400';
