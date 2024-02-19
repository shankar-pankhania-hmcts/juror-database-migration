/*
 * Task 5297
 * 
 * BULK_PRINT_DATA
 * ---------------
 * 
 * Migrate data from JUROR.PRINT_FILES to juror_mod.bulk_print_data
 * 
 */

ALTER TABLE juror_mod.bulk_print_data 
	DROP constraint IF EXISTS bulk_print_data_fk_form_type;

ALTER TABLE juror_mod.bulk_print_data 
	DROP CONSTRAINT IF EXISTS bulk_print_data_juror_no_fk;

truncate table juror_mod.bulk_print_data RESTART IDENTITY cascade;

with rows
as
(
 	INSERT into juror_mod.bulk_print_data (juror_no,creation_date,form_type,detail_rec,extracted_flag,digital_comms)
	SELECT DISTINCT 
			pf.part_no,
			pf.creation_date,
			pf.form_type,
			pf.detail_rec,  -- contains ref+fname+lname+address+postcode as fixed length characters
			case UPPER(pf.extracted_flag)
				when 'Y' 
					then true
					else false
			END,
			case UPPER(pf.digital_comms)
				when 'Y' 
					then true
					else false
			END
	FROM juror.print_files pf
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected

-- verify results
select COUNT(*) FROM juror.print_files;
select * FROM juror_mod.bulk_print_data limit 10;

ALTER TABLE juror_mod.bulk_print_data 
	ADD CONSTRAINT bulk_print_data_fk_form_type FOREIGN KEY (form_type) REFERENCES juror_mod.t_form_attr(form_type) NOT valid;

ALTER TABLE juror_mod.bulk_print_data 
	ADD CONSTRAINT bulk_print_data_juror_no_fk FOREIGN KEY (juror_no) REFERENCES juror_mod.juror(juror_number) NOT valid;

