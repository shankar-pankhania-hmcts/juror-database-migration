/*
 * Task: 6145 - Develop migration script(s) to migrate the DISQ_LETT table (court data)
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
					dl.date_disq as other_information_date,
					dl.disq_code as other_information_reference,
					dl.date_printed
			FROM Juror.disq_lett dl
			WHERE dl.date_printed is not null
			AND dl.owner != '400'
	) as l
	WHERE juror_mod.juror_history.juror_number = l.part_no
	AND juror_mod.juror_history.date_created = l.date_printed
	AND juror_mod.juror_history.history_code = 'RDIS'
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/*
 * Verify results
 */
select count(*) 
FROM Juror.disq_lett dl
join juror_mod.juror_history jh
on  jh.juror_number = dl.part_no
AND jh.date_created = dl.date_printed
AND jh.history_code = 'RDIS'
WHERE dl.date_printed is not null 
AND dl.owner != '400';

