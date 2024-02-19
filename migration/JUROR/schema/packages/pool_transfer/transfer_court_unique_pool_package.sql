-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;

/**************************************************************************************************/

/************************************************************************
*
*
*	Procedure:	transfer_court_unique_pool                   			 *
*
*
*	Access:		private													 *
*
*
 *	Arguments:	location code											 *
 *
 *
 *	Returns:	None 			                   					 *
 *
 *
 *	Description:	This procedure transfers pool reuests created at bureau for the courts
 * 					from SUPS bureau to SUPS court              		 *
 *									   		  	  						 *
 *
 *	Name		  Date		  Action										 *
 *	====		  ====		  ======										 *
 *	Joy       21/09/05	Created this procedure						 *
 *  Chris W   20/11/15  Get pool transfer adjustment from court_location table
 *                       - enables early transfer of pools
 *                         e.g. set adjustment to 7 to bring the pool transfer window a week earlier
 ************************************************************************/
CREATE OR REPLACE PROCEDURE pool_transfer_transfer_court_unique_pool (location_code text) AS $body$
DECLARE

ora2pg_rowcount int;
ln_up_ins_records bigint:=0;
ln_up_found bigint:=0;
C5_unique_pool CURSOR(location_code text) FOR
          SELECT  pool_no,
		   		  jurisdiction_code,
				  date_trunc('day', return_date) return_date,
				  next_date,
				  pool_total,
				  no_requested,
				  reg_spc,
				  pool_type,
				  u.loc_code,
				  new_request,
				  read_only
		   FROM	  unique_pool u, court_location c
		   WHERE u.owner = '400'
       AND read_only = 'N'
       and c.loc_code = u.loc_code
		   AND date_trunc('day', return_date) <= ld_LatestReturnDate + coalesce(pool_transfer_adjustment_days,0)
		   AND  u.loc_code in (SELECT loc_code from context_data where context_id = location_code);

BEGIN
	 For unique_pool_recs in c5_unique_pool(location_code)
	 Loop
	 EXIT WHEN NOT FOUND; /* apply on c5_unique_pool */

	 SELECT count(1)
	 INTO STRICT ln_up_found
	 FROM unique_pool
	 WHERE OWNER=location_code
	 AND  pool_no= unique_pool_recs.pool_no;

     IF ln_up_found = 0 THEN

 			INSERT INTO unique_pool(owner,
					   		  	   			   pool_no,
											   jurisdiction_code,
											   return_date,
											   next_date,
											   pool_total,
											   no_requested,
											   reg_spc,
											   pool_type,
											   loc_code,
											   new_request,
											   read_only)
					  				    VALUES ( location_code,unique_pool_recs.pool_no,
											   unique_pool_recs.jurisdiction_code,
											   unique_pool_recs.return_date,
											   unique_pool_recs.next_date,
											   unique_pool_recs.pool_total,
											   unique_pool_recs.no_requested,
											   unique_pool_recs.reg_spc,
											   unique_pool_recs.pool_type,
											   unique_pool_recs.loc_code,
											   'N',
											   'N'
											   );
						GET DIAGNOSTICS ora2pg_rowcount = ROW_COUNT;

						ln_up_ins_records := ln_up_ins_records+  ora2pg_rowcount;


   Else
                   UPDATE unique_pool
				   SET	  jurisdiction_code  = unique_pool_recs.jurisdiction_code,
				   		  return_date 	   	 = unique_pool_recs.return_date,
						  next_date		   	 = unique_pool_recs.next_date,
						  pool_total	   	 = unique_pool_recs.pool_total,
						  no_requested	   	 = unique_pool_recs.no_requested,
						  reg_spc		   	 = unique_pool_recs.reg_spc,
						  pool_type		   	 = unique_pool_recs.pool_type,
						  loc_code		   	 = unique_pool_recs.loc_code,
						  new_request	   	 = 'N',
						  read_only		   	 = CASE WHEN 'OWNER'='400' THEN 'Y'  ELSE 'N' END
					WHERE pool_no = unique_pool_recs.pool_no;

   End If;
	-- update unique_pool read_only flag in Bureau
			UPDATE unique_pool SET read_only ='Y'
			, new_request = 'N'
			WHERE pool_no = unique_pool_recs.pool_no
			AND owner ='400';
End loop;

Exception
	when others then
		CALL pool_transfer_write_error_message('POOL TRANSFER','Error in TRANSFER_COURT_UNIQUE_POOL Package. '||SUBSTR(SQLERRM, 1, 100));
		rollback;
		raise;
END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE pool_transfer_transfer_court_unique_pool (location_code text) FROM PUBLIC;
