CREATE OR REPLACE PROCEDURE juror_mod.delete_printfiles()
LANGUAGE plpgsql
AS
/***********************************************************************************************************************
*  Author  : Andrew Fraser
*  Created : 8 March 2024
*  Purpose : The steps in the user letters procedure that generate and insert print data are no longer needed as the
* 	 		 application is generating the bulk print data itself. The steps that delete redundant letter requests are 
* 			 still needed but they can be replaced by a bulk_print_data delete statement to be added to the print files 
* 			 to clob package.
*
* 			 Called by payment_files_to_clob.
* 
*   Change History:
*
*   Ver  Date     Author     Description
*   ---  ----     ------     -----------
*
***********************************************************************************************************************/
$$
BEGIN
	DELETE
	FROM juror_mod.bulk_print_data bpd
	WHERE COALESCE (bpd.extracted_flag,'N') = 'N'
	AND EXISTS 	(
					SELECT 1
					FROM juror_mod.juror_pool jp
					WHERE jp.juror_number = bpd.juror_no
					AND jp.is_active = true
					AND (
							(bpd.form_type IN ('5224','5224C') AND jp.status <> 6) -- withdrawal letters
			                OR 
			                (bpd.form_type IN ('5225','5225C') AND jp.status <> 5) -- excusal letters
			                OR 
			                (bpd.form_type IN ('5226','5226C') AND jp.status <> 2) -- excusal denied letters
			                OR 
			                (bpd.form_type IN ('5226A','5226AC') AND jp.status <> 2) -- deferral denied letters
			                OR 
			                (bpd.form_type IN ('5227','5227C') AND jp.status <> 1) -- request for info letters
			                OR 
			                (bpd.form_type IN ('5229','5229C') AND jp.status <> 7) -- postpone letters
			                OR 
			                (bpd.form_type IN ('5229A','5229AC') AND jp.status not in (2,7)) -- deferral letters
			             	OR 
			             	(bpd.form_type IN ('5229A','5229AC') AND jp.status = 2 AND COALESCE(jp.was_deferred,false) = false) -- deferral letters, deferral deleted
						)                 
				);
END;
$$