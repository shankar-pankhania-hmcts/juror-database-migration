CREATE OR REPLACE PROCEDURE juror_mod.payment_files_to_clob (p_limit INTEGER DEFAULT 1000000)
LANGUAGE plpgsql
AS
/***********************************************************************************************************************
*  Author  : Andrew Fraser
*  Created : 6 March 2024
*  Purpose : Loops through each creation date and creates payment file records based on date 
* 
*   Change History:
*
*   Ver  Date     Author     Description
*   ---  ----     ------     -----------
*
***********************************************************************************************************************/
$$
DECLARE
	payments RECORD;
	v_file_name VARCHAR(255);
	v_creation_date DATE;
	v_total NUMERIC(8, 2);

BEGIN
	
	FOR payments IN
		SELECT 	DATE_TRUNC('day', pd.creation_date) as creation_date,
   				SUM(pd.total) as total
      	FROM (
					SELECT 	DATE_TRUNC('day', pd.creation_date) as creation_date,
			   				pd.expense_total as total
			      	FROM juror_mod.payment_data pd
			      	WHERE DATE_TRUNC('day', pd.creation_date) <= DATE_TRUNC('day', CURRENT_TIMESTAMP) -- need to check this date range as 
			        AND pd.expense_file_name IS NULL
			 ) pd
  		GROUP BY pd.creation_date
        ORDER BY pd.creation_date

		LOOP
        
			SELECT 	payments.creation_date,
					payments.total
			INTO v_creation_date, v_total;
		
            CALL juror_mod.payment_files_to_clob_write_to_clob(v_creation_date,v_total,v_file_name);

           	UPDATE juror_mod.payment_data
            SET expense_file_name = v_file_name
            WHERE DATE_TRUNC('day', creation_date) = payments.creation_date;
   
     END LOOP;
    
 END;
 $$
 
