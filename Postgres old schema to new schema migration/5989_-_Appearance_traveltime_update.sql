/*
 * Task: 5989 - Update the migration script(s) for appearance (and appearance_audit) table(s)
 * 
 */ 

ALTER TABLE juror_mod.appearance
	DROP COLUMN IF EXISTS travel_time;

ALTER TABLE juror_mod.appearance
	ADD COLUMN travel_time time;

ALTER TABLE juror_mod.appearance
ADD COLUMN IF NOT EXISTS pay_attendance_type varchar(25) NULL,
ADD COLUMN IF NOT EXISTS travel_jurors_taken_by_car int4 NULL,
ADD COLUMN IF NOT EXISTS travel_by_car bool NULL,
ADD COLUMN IF NOT EXISTS travel_jurors_taken_by_motorcycle int4 NULL,
ADD COLUMN IF NOT EXISTS travel_by_motorcycle bool NULL,
ADD COLUMN IF NOT EXISTS travel_by_bicycle bool NULL,
ADD COLUMN IF NOT EXISTS miles_traveled int4 NULL,
ADD COLUMN IF NOT EXISTS food_and_drink_claim_type varchar(20) NULL;


/*
 * Appearance_audit update
 * 
 */

ALTER TABLE juror_mod.appearance_audit 
	DROP COLUMN IF EXISTS travel_time;

ALTER TABLE juror_mod.appearance_audit
	ADD COLUMN travel_time time;

ALTER TABLE juror_mod.appearance_audit
ADD COLUMN IF NOT EXISTS pay_attendance_type varchar(25) NULL,
ADD COLUMN IF NOT EXISTS travel_jurors_taken_by_car int4 NULL,
ADD COLUMN IF NOT EXISTS travel_by_car bool NULL,
ADD COLUMN IF NOT EXISTS travel_jurors_taken_by_motorcycle int4 NULL,
ADD COLUMN IF NOT EXISTS travel_by_motorcycle bool NULL,
ADD COLUMN IF NOT EXISTS travel_by_bicycle bool NULL,
ADD COLUMN IF NOT EXISTS miles_traveled int4 NULL,
ADD COLUMN IF NOT EXISTS food_and_drink_claim_type varchar(20) NULL;

