/*
 * Task: 5559 - Develop migration script(s) to migrate the STATS tables to the new juror_dashboard schema
 */

/*
 * STATS_DEFERRALS
 */
TRUNCATE TABLE juror_dashboard.stats_deferrals;

WITH rows
AS
(
	INSERT INTO juror_dashboard.stats_deferrals(bureau_or_court,exec_code,calendar_year,financial_year,week,excusal_count)
	SELECT bureau_or_court,exec_code,calendar_year,financial_year,week,excusal_count 
	FROM juror_digital.STATS_DEFERRALS
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* verify results */
SELECT COUNT(*) from juror_digital.STATS_DEFERRALS;
SELECT * FROM juror_dashboard.stats_deferrals LIMIT 10;

/*
 * STATS_EXCUSALS
 */
TRUNCATE TABLE juror_dashboard.stats_excusals;

WITH rows
AS
(
	INSERT INTO juror_dashboard.stats_excusals(bureau_or_court,exec_code,calendar_year,financial_year,week,excusal_count)
	SELECT bureau_or_court,exec_code,calendar_year,financial_year,week,excusal_count
	FROM juror_digital.STATS_EXCUSALS
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* verify results */
SELECT COUNT(*) from juror_digital.STATS_EXCUSALS;
SELECT * FROM juror_dashboard.stats_excusals LIMIT 10;


/*
 * STATS_NOT_RESPONDED
 */
TRUNCATE TABLE juror_dashboard.stats_not_responded;

WITH rows
AS
(	
	INSERT INTO juror_dashboard.stats_not_responded(summons_month,loc_code,non_responsed_count)
	SELECT summons_month,loc_code,non_responsed_count 
	FROM juror_digital.STATS_NOT_RESPONDED	
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* verify results */
SELECT COUNT(*) from juror_digital.STATS_NOT_RESPONDED;
SELECT * FROM juror_dashboard.stats_not_responded LIMIT 10;


/*
 * STATS_RESPONSE_TIMES
 */
TRUNCATE TABLE juror_dashboard.stats_response_times;

WITH rows
AS
(	
	INSERT INTO juror_dashboard.stats_response_times(summons_month,response_month,response_period,loc_code,response_method,response_count)
	SELECT summons_month,response_month,response_period,loc_code,response_method,response_count
	FROM juror_digital.STATS_RESPONSE_TIMES
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* verify results */
SELECT COUNT(*) from juror_digital.STATS_RESPONSE_TIMES;
SELECT * FROM juror_dashboard.stats_response_times LIMIT 10;


/*
 * STATS_THIRDPARTY_ONLINE
 */
TRUNCATE TABLE juror_dashboard.stats_thirdparty_online;

WITH rows
AS
(	
	INSERT INTO juror_dashboard.stats_thirdparty_online(summons_month,thirdparty_response_count )
	SELECT summons_month,thirdparty_response_count 
	FROM juror_digital.STATS_THIRDPARTY_ONLINE
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* verify results */
SELECT COUNT(*) from juror_digital.STATS_THIRDPARTY_ONLINE;
SELECT * FROM juror_dashboard.stats_thirdparty_online LIMIT 10;


/*
 * STATS_AUTO_PROCESSED
 */
TRUNCATE TABLE juror_dashboard.stats_auto_processed;

WITH rows
AS
(	
	INSERT INTO juror_dashboard.stats_auto_processed(processed_date,processed_count)
	SELECT processed_date,processed_count
	FROM juror_digital.STATS_AUTO_PROCESSED
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* verify results */
SELECT COUNT(*) from juror_digital.STATS_AUTO_PROCESSED;
SELECT * FROM juror_dashboard.stats_auto_processed LIMIT 10;


/*
 * STATS_UNPROCESSED_RESPONSES
 */
TRUNCATE TABLE juror_dashboard.stats_unprocessed_responses;

WITH rows
AS
(	INSERT INTO juror_dashboard.stats_unprocessed_responses(loc_code,unprocessed_count)
	SELECT loc_code,unprocessed_count
	FROM juror_digital.STATS_UNPROCESSED_RESPONSES
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* verify results */
SELECT COUNT(*) from juror_digital.STATS_UNPROCESSED_RESPONSES;
SELECT * FROM juror_dashboard.stats_unprocessed_responses LIMIT 10;


/*
 * SURVEY_RESPONSE
 */
TRUNCATE TABLE juror_dashboard.survey_response;

WITH rows
AS
(	
	INSERT INTO juror_dashboard.survey_response(id,survey_id,user_no,survey_response_date,satisfaction_desc,created)
	SELECT id,survey_id,user_no,survey_response_date,satisfaction_desc,created
	FROM juror_digital.SURVEY_RESPONSE
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* verify results */
SELECT COUNT(*) from juror_digital.SURVEY_RESPONSE;
SELECT * FROM juror_dashboard.survey_response LIMIT 10;


/*
 * STATS_WELSH_ONLINE_RESPONSES
 */
TRUNCATE TABLE juror_dashboard.stats_welsh_online_responses;

WITH rows
AS
(	
	INSERT INTO juror_dashboard.stats_welsh_online_responses(summons_month,welsh_response_count)
	SELECT summons_month,welsh_response_count 
	FROM juror_digital.STATS_WELSH_ONLINE_RESPONSES
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

/* verify results */
SELECT COUNT(*) from juror_digital.STATS_WELSH_ONLINE_RESPONSES;
SELECT * FROM juror_dashboard.stats_welsh_online_responses LIMIT 10;
