CREATE OR REPLACE PROCEDURE juror_mod.printfiles_to_clob (p_limit INTEGER DEFAULT 1000000)
LANGUAGE plpgsql
AS
/***********************************************************************************************************************
*  Author  : Andrew Fraser
*  Created : 6 March 2024
*  Purpose : Loops through each form type and creates print file records based on the type and date 
* 
*   Change History:
*
*   Ver  Date     Author     Description
*   ---  ----     ------     -----------
*
***********************************************************************************************************************/
$$
DECLARE
	v_form_type VARCHAR(6);
	v_max_rec_len INTEGER;
	v_ext_date DATE;
	forms RECORD;
	v_count INTEGER:=0;

BEGIN
	v_ext_date :=	CASE 
						WHEN TO_CHAR(NOW(),'SSSSS')::INTEGER < 64800
              				THEN NOW()::date - 1
               				ELSE NOW()
              		END;
	
    -- delete redundant letter requests
	CALL juror_mod.delete_printfiles();
              
	FOR forms IN
		SELECT	fr.form_type,
				fr.max_rec_len::integer
		FROM juror_mod.t_form_attr fr
		
		LOOP
			CALL juror_mod.write_printfiles(forms.form_type, forms.max_rec_len, v_ext_date, p_limit, v_count);
			IF v_count >= p_limit THEN
				EXIT;
			END IF;
	END LOOP;

END;
$$
