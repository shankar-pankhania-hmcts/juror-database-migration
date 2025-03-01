-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';
SET search_path = JUROR,public;




CREATE OR REPLACE PROCEDURE phoenix_police_check () AS $body$
DECLARE
  l_check_on        varchar(1);
  l_lett_printed    varchar(1);
  lc_Job_Type text := 'phoenix_POLICE_CHECK()';

  police_check CURSOR FOR
  SELECT part_no,
         pool_no,
         phoenix_date,
         phoenix_checked,
         lname,
         fname,
         zip,
	 dob,
	 loc_code,
	 police_check
  from   pool
  where  dob is not null
  and (read_only is null or read_only = 'N')
  and    zip is not null
  and    status = 2
  and    coalesce(police_check, '^') != 'E'
  and    phoenix_date is not null
  and    phoenix_checked is null
  and    is_active = 'Y'
  and    owner = '400';  

BEGIN

  for each_participant in police_check loop
	BEGIN
       	   select printed
       	   into STRICT   l_lett_printed
       	   from   confirm_lett
       	   where  confirm_lett.part_no = each_participant.part_no;
	EXCEPTION
           when no_data_found then
           l_lett_printed := null;
      	END;

	if (l_lett_printed is null) then
      	BEGIN
	   update pool
	   set phoenix_date = date_trunc('day', clock_timestamp()),
	   police_check = 'E'
	   where pool_no  = each_participant.pool_no
	   and   part_no = each_participant.part_no
	   and   is_active = 'Y'
	   and   owner = '400';


       	   -- RFS 3681 Changed value for Other_information column
           insert into part_hist(owner,
				part_no,
                       		date_part,
                    		history_code,
                       		user_id,
                       		other_information,
                       		pool_no)
           values ('400',
				each_participant.part_no,
                       		clock_timestamp(),
                       		'POLE',
                       		'SYSTEM',
                       		'Check requested',
                       		each_participant.pool_no);

           insert into phoenix_temp(part_no,
                               	last_name,
                               	first_name,
                               	postcode,
                               	date_of_birth,
                               	result,
                               	checked)
           values (each_participant.part_no,
                               	each_participant.lname,
                               	each_participant.fname,
                               	each_participant.zip,
                               	each_participant.dob,
                               	null,
                               	null);
           END;
	end if;

  end loop;

EXCEPTION
   when others then
	CALL phoenix_write_error(sqlerrm);
     	rollback;
	raise;

END;

$body$
LANGUAGE PLPGSQL
;
-- REVOKE ALL ON PROCEDURE phoenix_police_check () FROM PUBLIC;
