/*
 * Task: 6026 - Update the migration script for juror table with new property bureau_transfer_date
 * 
 * 		- the source data for migration is the transfer_date column on the latest is_active = true, read_only = true bureau owned record 
 * 		- if there is an anomaly and the transfer_date is not present on a read_only, active bureau record, then default the value to 
 * 			the earliest court owned juror_pool.pool.ret_date - 10 days

 */
 
UPDATE juror_mod.juror
SET bureau_transfer_date =	CASE 
								WHEN p.transfer_date IS NOT NULL
									THEN p.transfer_date
									-- if not set...
									ELSE 
										(
											-- identify earliest ret_date for the same pool owned by the court
											SELECT MIN(p2.ret_date) - INTERVAL '10 DAY'
											FROM juror.pool p2
											WHERE p2.pool_no = p.pool_no
											AND p2.owner != '400'  -- court owned
										 )
							END
FROM juror_mod.juror j
JOIN juror.pool p
ON j.juror_number = p.part_no
WHERE p.owner = '400' AND UPPER(p.is_active) = 'Y' AND UPPER(p.read_only) = 'Y'; -- identify bureau owned active and read_only records
