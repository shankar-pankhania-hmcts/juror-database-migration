CREATE OR REPLACE PROCEDURE juror_mod.write_printfiles(p_form_type VARCHAR(6), p_max_rec_len INTEGER, p_ext_date DATE, p_limit INTEGER, INOUT p_count INTEGER)
LANGUAGE plpgsql
AS
/***********************************************************************************************************************
*  Author  : Andrew Fraser
*  Created : 6 March 2024
*  Purpose : Creates print file records based on the type and date for data that has not yet been extracted.
* 
*   Change History:
*
*   Ver  Date     Author     Description
*   ---  ----     ------     -----------
*
***********************************************************************************************************************/
$$
DECLARE
	form_details RECORD;
	v_filename VARCHAR(50); 
	v_header VARCHAR(50);
	v_row_id INTEGER;
	v_count INTEGER:=1;
	v_strpos INTEGER:=1;
	v_max_loop_count float;
	v_data text:=null;
	v_line text:='';
	v_max_data_len float;
	v_detail_rec text;
	v_revision int8;
   	v_text_var1 VARCHAR(255);
   	v_text_var2 VARCHAR(255);
   	v_text_var3 VARCHAR(255);
	v_print_msg VARCHAR(255);

BEGIN
	
	FOR form_details IN
		SELECT 	ROW_NUMBER() OVER () as counter,
				bpd.id,
				REPLACE(REPLACE(bpd.detail_rec,CHR(10),' '),CHR(13),' ') detail_rec
		FROM juror_mod.bulk_print_data bpd
		WHERE bpd.form_type = p_form_type
		AND COALESCE(bpd.extracted_flag,'N') = 'N'
		AND DATE(bpd.creation_date) <= p_ext_date

	LOOP
		-- increment the loop counter so that the process can be stopped if it reaches the threshold
		p_count := p_count + 1;	
		IF p_count >= p_limit THEN
			EXIT;
		END IF;

		-- Identify the next sequence number
		SELECT  NEXTVAL('juror_mod.content_store_seq') INTO v_revision;
		
		-- Form the data column details first	
		SELECT 	form_details.id,
				'JURY'||LPAD(v_revision::VARCHAR(22),4,'0')||'01.0001',
				RPAD('   ' ||RPAD(p_form_type,16)||LPAD(form_details.counter::VARCHAR(20),6,'0')||LPAD(form_details.counter::VARCHAR(20),6,'0')||'50'||LPAD(p_max_rec_len::VARCHAR(20),8,'0'),256,' '),
				form_details.detail_rec
		INTO v_row_id, v_filename, v_header, v_detail_rec;
	
		SELECT LENGTH(form_details.detail_rec)
		INTO v_max_data_len;	
	
		-- round up the division to the nearest whole number - e.g. 1.4 would equate to 2
		SELECT CEIL(v_max_data_len/p_max_rec_len)
		INTO v_max_loop_count;

		-- First line
		SELECT v_header||chr(10)
		INTO v_data;

		-- reset the starting string position
		v_strpos := 1;
		v_count := 1;
		-- Multiple lines for the details under the header if it exceeds the max record threshold
		FOR v_count IN 1..v_max_loop_count loop
			IF LENGTH(v_line) > 0  THEN 
				v_data := v_data||v_line||CHR(10); -- add line details to the data column		
			END IF;
			v_strpos := v_strpos + p_max_rec_len;  -- increment the string position identifier so that the next line starts from the end of the previous line counter
	 	END LOOP;
	
		-- Create the record
		INSERT INTO juror_mod.content_store(request_id,document_id,file_type,data) 
		VALUES (v_revision,v_filename,'PRINT',v_data);

		UPDATE juror_mod.bulk_print_data 
		SET  extracted_flag = 'Y'	
		WHERE id = v_row_id;

		COMMIT;

	END LOOP;
	
END;
$$
