-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.4;sid=xe;port=1521

SET client_encoding TO 'UTF8';

\set ON_ERROR_STOP ON

CREATE OR REPLACE package COURT_PHOENIX is

  -- Author  : D303633
  -- Created : 13/05/2015 12:09:34
  -- Purpose : Procedures for CPNC 
  
  PROCEDURE populate_court_checks(l_part_no varchar2, l_user varchar2);
  PROCEDURE finalise;

end COURT_PHOENIX;



CREATE OR REPLACE package body COURT_PHOENIX AS
  
   PROCEDURE	    write_error(p_info varchar2);
   FUNCTION  jurorFirstName( name_in VARCHAR2 )  RETURN VARCHAR2;
   FUNCTION  jurorMiddleName( name_in VARCHAR2 )  RETURN VARCHAR2;
   FUNCTION  jurorSurname( name_in VARCHAR2 )  RETURN VARCHAR2;
   FUNCTION  jurorCleanName( name_in VARCHAR2 )  RETURN VARCHAR2;
   
lc_Job_Type	    error_log.JOB%type;

/**************************
* Procedure court_phoenix.populate_court_checks
* PT 28/04/2015 Populate court_police_checks table
* CW 01/06/2015 Added l_user argument
**************************/
PROCEDURE populate_court_checks(l_part_no varchar2, l_user varchar2) IS
  
  l_court_juror pool%ROWTYPE;
  l_pool_no number;
  l_fname varchar(20);
  l_middle_name varchar(20);
  l_sur_name varchar(20);
  l_zip varchar(20);
  l_dob date;
  
BEGIN
lc_Job_Type := 'COURT_PHOENIX.POPUALTE_COURT_CHECKS';

 /** Get data from pool table to juror */
  select *
  into l_court_juror 
  from pool 
  where part_no = l_part_no
  and    is_active = 'Y';
  /** store data in local variables */
  l_pool_no := l_court_juror.pool_no;
  l_sur_name := l_court_juror.lname;
  l_fname := l_court_juror.fname;
  l_middle_name := l_fname;
  l_dob := l_court_juror.dob;
  l_zip := l_court_juror.zip;
  
  /** Parse name */ 
   IF ( ( l_fname is NULL ) OR ( l_sur_name is NULL ) ) THEN
		 write_error('Juror ' || l_part_no || ' contains null data');
            ELSE
            /***** BUG: If name is null error is generated, but insert runs anyway *****/
	   BEGIN
			l_fname := jurorFirstName( replace(replace(regexp_replace(l_fname,'[ ]+',' '),' -','-'),'- ','-'));
      l_middle_name := jurorMiddleName( replace(replace(regexp_replace(l_middle_name,'[ ]+',' '),' -','-'),'- ','-') );
      l_sur_name := jurorSurname( replace(replace(regexp_replace(l_sur_name,'[ ]+',' '),' -','-'),'- ','-') );

      /** insert rows to court_police_checks ready for phoenix run */
      insert into juror_court_police_check (id,
                               	surname,
                               	first_name,
                                last_name,
                               	postcode,
                               	dob,
                               	disqualified,
                               	check_complete,
                                try_count)
           values (l_part_no,
                   l_sur_name,
                   l_fname,
                   l_middle_name,
                   UPPER(REPLACE(l_zip, ' ' )),
                   l_dob,
                   'N','N',0);
               		
            	EXCEPTION
               		WHEN OTHERS THEN
                	write_error( 'Error on writing '|| l_part_no || ' to juror table for checking ');
			            ROLLBACK;
			            RAISE;
            	END;
	    /*END IF;
      --END;*/
  
      /** insert rows to part_hist for history */      
      insert into part_hist (part_no,
                       		date_part,
                    	  	history_code,
                       		user_id,
                       		other_information,
                       		pool_no)
           values (l_part_no,
                       		sysdate,
                       		'POLE',
                       		l_user,
                       		'Check Requested',
                       		l_pool_no);
                          
   /** Update pool table + phoenix_date
   -- Note: owner included in where clause by Oracle becuase context is already set */
     update pool
	   set phoenix_date = trunc(sysdate),
	   police_check = 'E',
    	   user_EDTQ = l_user
	   where part_no = l_part_no
	   and is_active = 'Y'; 
  
    END IF; /** End if on null names */
        
          --COMMIT; --Removed as app will perform commit
          EXCEPTION
            when others then
	          write_error(sqlerrm);
     	      rollback;
	          raise;
END populate_court_checks;

/************************************************************************
 *	FUNCTION:	jurorMiddleName( name_in VARCHAR2 )
 *	Access  :	private
 *	Args In :	name_in (juror first name)
 *	Returns :	s_name (Varchar2)
 *
 *	Desc    :	This function analyses the jurors first name and determines if it
 *            contains compeonents such as initials and middle names.
 *            the middle name.
 *
 *            This function will :
 *            1) Remove unwanted chars from the middle name (see Jurorcleanname)
 *            2) Remove the first name if other component names are present
 *            3) Separate each component of the middlename with a '/'
 *            4) Remove leading and trailing spaces...
 *            Example: Daniel [SNR] Jake Lewis --> Jake/Lewis
 *                     William P.              --> P
 *
 *  History
 *
 *	Version Name		  Date		 Desc
 *	======= ========= ======== ====
 *  V1.0    ???       ???      Initial version
 *	V1.2    Kal Sohal 20/11/06 SCR 4341 PNC Errors.
 *	V1.3    Kal Sohal 05/01/07 SCR 4341 SCR 4341 - Fixed jurorMiddleName() system test bug which returned the
 *                             firstname as the middlename when no 'splits' found in
 *                             firstname.
 *                             i.e. Firstname=Frank,
 *                             before fix,Middlename=Frank
 *                             after fix, Middlename=empty string
 *	V1.4    Kal Sohal 08/01/07 SCR 4341 - jurorMiddleName() now returns NULL where middlename does not exist.
 *  V1.5    M Turton  21/03/11 Trac3897 Handle characters in () and []
 ************************************************************************/

   FUNCTION jurorMiddleName( name_in VARCHAR2 ) RETURN VARCHAR2 IS

      s_name               VARCHAR2(20);
      n_pos                NUMBER;

   BEGIN
      -- Replace all full stops and commas with a space and
      -- Remove anything within brackets () or [] and
      -- Remove leading and trailing spaces...
      --s_name := JurorCleanName(name_in); --Moved below for Trac3897 - ensure use middle name


      -- If there is a 'split' in the name, remove Firstname, otherwise there
      -- is no middle name to return.
      --n_pos := INSTR(s_name, ' ' ); Trac3897
      n_pos := INSTR(name_in, ' ' );

      IF n_pos > 0 THEN
         s_name := Substr(name_in, n_pos+1);   --Trac3897
      ELSE
         s_name := NULL;
      END IF;
      
      s_name := jurorCleanName(s_name);  --Trac3897

      -- Remove leading and trailing spaces and
      -- Replace all 1 or more occurances of space with a '/'
      s_name := REGEXP_REPLACE(TRIM(s_name), '( ){1,}', '/');

   Return UPPER(Trim(s_name));

   EXCEPTION
      WHEN OTHERS THEN
         write_error( 'Error in jurorMiddleName ' );

   END jurorMiddleName;

/************************************************************************
 *	FUNCTION:	jurorCleanName( name_in VARCHAR2 )
 *	Access  :	private
 *	Args In :	name_in (juror first name)
 *	Returns :	s_name (Varchar2)
 *
 *	Desc    :	This function 'cleans' the firstname to remove and convert unwanted characters or
 *            chars in the supplied firstname.
 *
 *            This function will :
 *            1) Replace all full stops and commas with a space and
 *            2) Remove anything within brackets () or []
 *            3) Convert NUll string to a empty string and
 *            4) Remove leading and trailing spaces...
 *
 *  History
 *
 *	Version Name		  Date		 Desc
 *	======= ========= ======== ====
 *	V1.0    Kal Sohal 20/11/06 Initial version
 *  V2.0    M Turton  21/03/11 Trac3897 Handle characters in () and []
 ************************************************************************/

   FUNCTION jurorCleanName( name_in VARCHAR2 ) RETURN VARCHAR2 IS

      s_name               VARCHAR2(20);
      n_pos1               NUMBER;
      n_pos2               NUMBER;

   BEGIN
      -- Replace all full stops and commas with a space
      s_name := REPLACE( name_in, '.', ' ');
      s_name := REPLACE( s_name, ',', ' ');

      -- Remove anything within '(' or ')'
      n_pos1 := INSTR(s_name, '(');
      n_pos2 := INSTR(s_name, ')');

      IF (n_pos1 > 0 AND n_pos2 > 0) THEN
         s_name := Substr(s_name, 1, n_pos1 -1) || ' ' || Substr(s_name, n_pos2 + 1) ;
      END IF;

      -- Remove anything within '[' or ']'
      n_pos1 := INSTR(s_name, '[');
      n_pos2 := INSTR(s_name, ']');

      IF (n_pos1 > 0 AND n_pos2 > 0) THEN
         s_name := Substr(s_name, 1, n_pos1 -1) || ' ' || Substr(s_name, n_pos2 + 1) ;
      END IF;

   return Trim(s_name);

   EXCEPTION
      WHEN OTHERS THEN
         write_error( 'jurorCleanName ' );

   END jurorCleanName;
   
/************************************************************************
 *	FUNCTION:	jurorFirstName( name_in VARCHAR2 )
 *	Access  :	private
 *	Args In :	name_in (juror first name)
 *	Returns :	s_name (Varchar2)
 *
 *	Desc    :	This function analyses the jurors first name and returns a single first name
 *            having determined if it contains components names such as to such as initials
 *            titles and middlenames etc.
 *
 *            This function will :
 *            1) Remove unwanted chars from the middle name (see Jurorcleanname)
 *            2) Remove ALL BUT the first name if other component names are present
 *            Example: Daniel [SNR] Jake Lewis --> Daniel
 *                     [SNR] William P.        --> William
 *
 *  History
 *
 *	Version Name		  Date		 Desc
 *	======= ========= ======== ====
 *  V1.0    ???       ???      Initial version
 *	V1.2    Kal Sohal 20/11/06 SCR 4341 PNC Errors.
 *  V1.3    M Turton  21/03/11 Trac3897 Handle characters in () and []
 ************************************************************************/

FUNCTION jurorFirstName( name_in VARCHAR2 ) RETURN VARCHAR2 IS

      n_pos            NUMBER;
      s_name           VARCHAR2(20);

BEGIN

      -- Replace all full stops and commas with a space and
      -- Remove anything within brackets () or [] and
      -- Remove leading and trailing spaces...
      s_name := JurorCleanName(name_in);

      -- If there is a 'split' in the name, keep Firstname
      n_pos  := INSTR(s_name, ' ' );

      IF n_pos  > 0 THEN
         s_name := Substr(s_name, 1, n_pos-1);
      END IF;

      -- Check for NULL and return firstname in uppercase
      s_name := NVL(s_name, '~');  --Trac3897 If null supply tilde
      --Return UPPER(Trim(s_name));
      Return UPPER(s_name);

   EXCEPTION
      WHEN OTHERS THEN
         write_error( 'Error in jurorFirstName ' );

   END jurorFirstName;

/*****************************************************************************

 *  History
 *
 *	Version Name	   Date		Desc
 *	======= =========  ====		=====
 *	V1.0    x			Initial version
 *	V2.0    M Turton   15/03/11	Trac3897 Clean surname as per first and middle name
 ************************************************************************/

FUNCTION jurorSurname( name_in VARCHAR2 ) RETURN VARCHAR2 IS

      --space_pos            NUMBER;
      s_name               VARCHAR2(20);
      sur_name             VARCHAR2(20);
      temp_name            VARCHAR2(20);

   BEGIN
      -- Replace all full stops and commas with a space and
      -- Remove anything within brackets () or [] and
      -- Remove leading and trailing spaces...
      s_name := JurorCleanName(name_in);

      s_name := NVL(s_name, '~');  --Trac3897 If null supply tilde
      --s_name = Trim(s_name); --Trac3897 - remove spaces before and after

      --temp_name := REPLACE( name_in, '`', '''' ); //Trac3697 
      temp_name := REPLACE( s_name, '`', '''' );
      sur_name := REPLACE( temp_name, ',', '''' );
      temp_name := REPLACE( sur_name, ' ' );
      return UPPER(REPLACE( temp_name, '.' ) );

   EXCEPTION
      WHEN OTHERS THEN
         write_error( 'Error in jurorSurname ');

   END jurorSurname;

/**************************
* Procedure COURT_PHOENIX.FINALISE
* Context not set for finalise
* 27/05/15 C Wright Fixed defect in decode setting other_information
**************************/
PROCEDURE finalise is

  cursor court_police_check is
  select t.owner cpnc_owner,
         t.id,
         t.last_name,
         t.first_name,
         t.postcode,
         t.dob,
         t.disqualified,
         t.check_complete,
         t.try_count,
         p.owner pool_owner,
	       p.pool_no,
	       p.read_only,
	       p.loc_code,
	       p.rowid row_idd
  from   juror_court_police_check t, pool p
  where  (t.try_count > 1 or t.check_complete = 'Y')
  and	 p.owner = t.owner
  and	 p.part_no = t.id
  and  p.is_active = 'Y';

begin
lc_Job_Type := 'COURT_PHOENIX.FINALISE';

  for each_participant in court_police_check loop

  update pool
  set phoenix_checked = decode(each_participant.try_count, 0,'C',1,'C',NULL,'C','U'),
			police_check = decode(each_participant.disqualified, 'N','P','Y','F'),
	    status = decode(each_participant.disqualified, 'N',status,'Y','6'),
		  disq_code = decode(each_participant.disqualified, 'Y','E',NULL),
		  date_disq = decode(each_participant.disqualified, 'Y',sysdate,NULL)
  where rowid = each_participant.row_idd;

  if each_participant.disqualified = 'N' then
        -- RFS 3681 Changed value for other_information
        insert into part_hist (owner,
			                       part_no,
                             date_part,
                             history_code,
                             user_id,
                             other_information,
                             pool_no)
                     values (each_participant.cpnc_owner,
			                      each_participant.id,
                            sysdate,
                            'POLG',
                            'SYSTEM',
                             decode(each_participant.try_count,'0','Passed','1','Passed',
                            NULL,'Unchecked - timed out','Unchecked - timed out'),
                            each_participant.pool_no);
  else
       insert into disq_lett (owner,
			                        part_no,
                              disq_code,
                              date_disq,
                              date_printed,
                              printed)
                       values (each_participant.cpnc_owner,
			                        each_participant.id,
                              'E',
                              sysdate,
                              null,
                              null);
        -- RFS 3681 Changed value for other_information
        insert into part_hist (owner,
			                         part_no,
                               date_part,
                               history_code,
                               user_id,
                               other_information,
                               pool_no)
                        values (each_participant.cpnc_owner,
			       			             each_participant.id,
                               sysdate,
                               'POLF',
                               'SYSTEM',
                               'Failed',
                               each_participant.pool_no);

        insert into part_hist (owner,
			       			            part_no,
                              date_part,
                              history_code,
                              user_id,
                              other_information,
                              pool_no)
                        values (each_participant.cpnc_owner,
			       			             each_participant.id,
                               sysdate+(1/86400),
                               'PDIS',
                               'SYSTEM',
                               'Disqualify - E',
                               each_participant.pool_no);
                               
       -- delete from defer.dbf table on owner and part_no 
       delete from defer_dbf where defer_dbf.owner = each_participant.cpnc_owner 
       and defer_dbf.part_no = each_participant.id;
       
     end if;

   end loop;

   delete from juror_court_police_check where try_count > 1 or check_complete = 'Y';

   commit;
   --return(0);

exception
     when others then
	write_error(sqlerrm);
	raise;
       --return(1);
end finalise;

/**************************
* Procedure 
*
**************************/
PROCEDURE write_error(p_info varchar2) IS
pragma autonomous_transaction;

BEGIN
    INSERT INTO ERROR_LOG (job, error_info) values (lc_Job_Type, p_info);
	 commit;
END write_error;

end COURT_PHOENIX;

