-- Generated by Ora2Pg, the Oracle database Schema converter, version 24.0
-- Copyright 2000-2023 Gilles DAROLD. All rights reserved.
-- DATASOURCE: dbi:Oracle:host=172.17.0.5;sid=xe;port=1521

SET client_encoding TO 'UTF8';

SET search_path = "JUROR",public;
\set ON_ERROR_STOP ON

CREATE OR REPLACE PACKAGE PhoenixInterface IS

   PROCEDURE preventDups;
   PROCEDURE readJurorRecords;
   PROCEDURE checkForCompletedChecks;

END PhoenixInterface;



CREATE OR REPLACE PACKAGE BODY PhoenixInterface AS

   err_text         VARCHAR2(2000);
   warn_text        VARCHAR2(2000);
   info_text        VARCHAR2(2000);

   to_next          EXCEPTION;
   no_inserts       EXCEPTION;
   no_table_or_view EXCEPTION;
   no_synonym       EXCEPTION;
   invalid_loc      EXCEPTION;
   lc_Job_Type	    error_log.JOB%type;

   PRAGMA EXCEPTION_INIT(no_inserts, -1400);
   PRAGMA EXCEPTION_INIT(no_table_or_view, -942);
   PRAGMA EXCEPTION_INIT(no_synonym, -1434);
   PRAGMA EXCEPTION_INIT(invalid_loc, -6502);

   -- Declare private procedures and functions

   PROCEDURE	write_error(p_info varchar2);
   FUNCTION  jurorFirstName( name_in VARCHAR2 )  RETURN VARCHAR2;
   FUNCTION  jurorMiddleName( name_in VARCHAR2 )  RETURN VARCHAR2;
   FUNCTION  jurorSurname( name_in VARCHAR2 )  RETURN VARCHAR2;
   FUNCTION  jurorCleanName( name_in VARCHAR2 )  RETURN VARCHAR2;

/* Procedure
*  ===========
*  preventDups()
***********************************************************************
*  M Turton 15/03/11 Trac3896 Prevent duplicate records in phoenix_temp
*                             from causing errors in batch job after
*                             a juror has had a pool reassignment.
*******************************************************************/
PROCEDURE preventDups IS

BEGIN

lc_Job_Type := 'PHOENIXINTERFACE.PREVENTDUPS';

   DELETE from phoenix_temp
   WHERE rowid NOT in (
   SELECT MIN(rowid) FROM phoenix_temp
   GROUP by part_no);
COMMIT;
EXCEPTION
      WHEN OTHERS THEN
         write_error( 'Error on deleting duplicates from phoenix_temp table');
	 ROLLBACK;
	 RAISE;

END preventDups;

/************************************************************
 *
 ************************************************************
 * Description
 * ===========
 *
 ************************************************************/

/************************************************************
 * readJurorRecords()
 ************************************************************
 * Description
 * ===========
 * This procedure is called to read all the jurors from the
 * JMS database that are ready for PNC checking and store
 * them in the Phoenix Interface database Juror table. It
 * only reads those jurors that are not already in the Juror
 * table. The jurors that are in the Juror table are those
 * that a check could not be performed for on the previous run,
 * normally due to an error.
 *
 *  History
 *
 *	Version Name		  Date		 Desc
 *	======= ========= ======== ====
 *  V1.0    ???       ???      Initial version
 *	V1.2    Kal Sohal 20/11/06 SCR 4341 PNC Errors.
 *	V1.3    Kal Sohal 05/01/07 SCR 4341 - Fixed jurorMiddleName() system test bug.
 *	V1.4    Kal Sohal 08/01/07 SCR 4341 - jurorMiddleName() now returns NULL where middlename does not exist.
*/
      PROCEDURE readJurorRecords IS

      first_name           VARCHAR2(20);
      sur_name             VARCHAR2(20);
      space_pos            NUMBER;
      middle_name          VARCHAR2(20);

      cursor c_read_juror IS SELECT part_no, first_name,
         last_name, postcode, date_of_birth FROM phoenix_temp
         WHERE result is null and
               part_no not in ( SELECT id from juror );

   BEGIN
      -- The various parts of this procedure are contained
      -- in seperate blocks to enable an error with one
      -- record to not stop the processing of others.

      lc_Job_Type := 'PHOENIXINTERFACE.READJURORRECORDS';

      FOR juror_rec IN c_read_juror LOOP
         BEGIN
            IF ( ( juror_rec.first_name = NULL ) OR
                 ( juror_rec.last_name = NULL ) ) THEN
		 write_error('Juror ' || juror_rec.part_no || 'contains null data');
            ELSE
		BEGIN
			first_name := jurorFirstName( replace(replace(regexp_replace(juror_rec.first_name,'[ ]+',' '),' -','-'),'- ','-') );

                  	middle_name := jurorMiddleName( replace(replace(regexp_replace(juror_rec.first_name,'[ ]+',' '),' -','-'),'- ','-') );

                  	sur_name := jurorSurname( replace(replace(regexp_replace(juror_rec.last_name,'[ ]+',' '),' -','-'),'- ','-') );

			INSERT INTO juror ( id, first_name, last_name, surname, postcode,
                                      dob, check_complete, disqualified,
                                      try_count )
                     	VALUES( juror_rec.part_no,
                              first_name,
                              middle_name,
                              sur_name,
                              UPPER(REPLACE( juror_rec.postcode, ' ' )),
                              juror_rec.date_of_birth,
                              'N', 'N', 0 );

               		COMMIT;
            	EXCEPTION
               		WHEN OTHERS THEN
                	write_error( 'Error on writing '|| juror_rec.part_no || ' to juror table for checking ');
			ROLLBACK;
			RAISE;
            	END;
	    END IF;
         END;

      END LOOP;

EXCEPTION
      WHEN OTHERS THEN
         write_error( 'Error on opening cursor on JMS juror table ');
	 ROLLBACK;
	 RAISE;

END readJurorRecords;

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

      s_name := JurorCleanName(s_name);  --Trac3897

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

/*****************************************************************************

 *  History
 *
 *	Version Name	   Date		Desc
 *	======= =========  ====		=====
 *	V1.0    x			Initial version
 *	V2.0    M Turton   15/03/11	Trac3897 Clean surname as per first and middle name
 ************************************************************************/

FUNCTION jurorSurname( name_in VARCHAR2 ) RETURN VARCHAR2 IS

      space_pos            NUMBER;
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

/************************************************************
 * checkForCompletedChecks()
 ************************************************************
 * Description
 * ===========
 * This procedure is called to check for completed PNC checks
 * in the Juror table and, if it finds any, write these back
 * to the JMS database. PNC checks are completed if the
 * CHECK_COMPLETE column is set to ?Y? or if the TRY_COUNT is
 * greater than one.
 ************************************************************/

   PROCEDURE checkForCompletedChecks IS

         juror_part_number    VARCHAR2(13);
	 disqualified         VARCHAR2(1);
         result_str           VARCHAR2(1);
	 check_str            VARCHAR2(1);
         jms_result           NUMBER;
	 retry_count          NUMBER;


         cursor c_read_juror IS SELECT id, disqualified, try_count FROM juror
            WHERE try_count > 1 or check_complete = 'Y';

      BEGIN
         -- The various parts of this procedure are contained
         -- in seperate blocks to enable an error with one
         -- record to not stop the processing of others.

	 lc_Job_Type := 'PHOENIXINTERFACE.CHECKFORCOMPLETEDCHECKS';

         OPEN c_read_juror;

         LOOP
            BEGIN
               FETCH c_read_juror INTO juror_part_number, disqualified, retry_count;

               IF disqualified = 'Y' THEN
                  result_str := 'F';
               ELSE
                  result_str := 'P';
               END IF;

	       IF retry_count > 1 THEN
                  check_str := 'U';
               ELSE
                  check_str := 'C';
               END IF;

               BEGIN
                  UPDATE phoenix_temp SET result = result_str, checked = check_str
                     WHERE part_no = juror_part_number;

                  BEGIN
                     DELETE FROM juror WHERE id = juror_part_number;
                  EXCEPTION
                     WHEN OTHERS THEN
                        write_error( 'Error on deleting juror from juror table ' );
			ROLLBACK;
			RAISE;
                  END;

               EXCEPTION
                  WHEN OTHERS THEN
                     write_error( 'Error on writing check result to JMS for ' || juror_part_number);
		     ROLLBACK;
		     RAISE;
               END;

               COMMIT;

            EXCEPTION
               WHEN OTHERS THEN
                  write_error( 'Error on fetching a juror to write result ' );
		  ROLLBACK;
		  RAISE;
            END;

            EXIT WHEN c_read_juror%NOTFOUND;
         END LOOP;

         CLOSE c_read_juror;

         jms_result := phoenix_checking.finalise();

         IF jms_result > 0 THEN
            write_error( 'Error on finalising results in JMS ' || jms_result );
	    ROLLBACK;
	    RAISE_APPLICATION_ERROR(-20903,'phoenix_checking.finalise has errored');
	 ELSE
	    COMMIT;
	 END IF;

      EXCEPTION
         WHEN OTHERS THEN
            write_error( 'Error on opening cursor on JMS juror table ' );
	    ROLLBACK;
	    RAISE;

   END checkForCompletedChecks;

PROCEDURE write_error(p_info varchar2) IS
pragma autonomous_transaction;

BEGIN
     INSERT INTO ERROR_LOG (job, error_info) values (lc_Job_Type, p_info);
	 COMMIT;
END write_error;


END PhoenixInterface;
