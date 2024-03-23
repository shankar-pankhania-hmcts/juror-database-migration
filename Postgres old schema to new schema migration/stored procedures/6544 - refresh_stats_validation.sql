DELETE FROM juror_mod.stats_auto_processed;
DELETE FROM juror_mod.stats_deferrals;
DELETE FROM juror_mod.stats_excusals;
DELETE FROM juror_mod.stats_not_responded;
DELETE FROM juror_mod.stats_response_times;
DELETE FROM juror_mod.stats_thirdparty_online;
DELETE FROM juror_mod.stats_unprocessed_responses;
DELETE FROM juror_mod.stats_welsh_online_responses;

delete from juror_mod.juror_history;
delete from juror_mod.juror_response;
delete from juror_mod.juror_pool;
delete from juror_mod.pool ;
delete from juror_mod.juror;

create TEMP TABLE expected_stats_response_times (
	summons_month timestamp NOT NULL,
	response_month timestamp NOT NULL,
	response_period varchar(15) NULL,
	loc_code varchar(3) NULL,
	response_method varchar(13) NULL,
	response_count int4 NULL
);


INSERT INTO expected_stats_response_times
(summons_month, response_month, response_period, loc_code, response_method, response_count)
VALUES('2024-03-01 00:00:00.000', '2024-03-01 00:00:00.000', 'Within 7 days', '415', 'Online', 3);

INSERT into expected_stats_response_times
(summons_month, response_month, response_period, loc_code, response_method, response_count)
VALUES('2024-03-01 00:00:00.000', '2024-03-01 00:00:00.000', 'Within 7 days', '415', 'Paper', 3);



CREATE temp table expected_stats_auto_processed (
	processed_date timestamp(0) NOT NULL,
	processed_count int4 DEFAULT 0 NULL
);

INSERT INTO expected_stats_auto_processed
(processed_date, processed_count)
VALUES('2024-03-19 00:00:00.000', 3);

INSERT INTO expected_stats_auto_processed
(processed_date, processed_count)
VALUES('2024-03-20 00:00:00.000', 3);


CREATE TEMP TABLE expected_stats_deferrals (
	bureau_or_court varchar(6) NOT NULL,
	exec_code varchar(1) NOT NULL,
	calendar_year varchar(4) NOT NULL,
	financial_year varchar(7) NOT NULL,
	week varchar(7) NOT NULL,
	excusal_count int4 NOT NULL
);
INSERT INTO expected_stats_deferrals (bureau_or_court,exec_code,calendar_year,financial_year,week,excusal_count) VALUES
	 ('Court','O','2024','2023/24','2024/12',3);



CREATE TEMP TABLE expected_stats_excusals (
	bureau_or_court varchar(6) NOT NULL,
	exec_code varchar(1) NOT NULL,
	calendar_year varchar(4) NOT NULL,
	financial_year varchar(7) NOT NULL,
	week varchar(7) NOT NULL,
	excusal_count int4 NOT NULL
);
INSERT INTO expected_stats_excusals (bureau_or_court,exec_code,calendar_year,financial_year,week,excusal_count) VALUES
	 ('Court','A','2024','2023/24','2024/12',3);


CREATE TEMP TABLE expected_stats_not_responded (
	summons_month timestamp(0) NOT NULL,
	loc_code varchar(3) NOT NULL,
	non_responsed_count int4 DEFAULT 0 NULL
);
INSERT INTO expected_stats_not_responded (summons_month,loc_code,non_responsed_count) VALUES
	 ('2024-03-01 00:00:00.000','415',1);


CREATE TEMP TABLE expected_stats_thirdparty_online (
	summons_month timestamp(0) NOT NULL,
	thirdparty_response_count int4 DEFAULT 0 NULL
);
INSERT INTO expected_stats_thirdparty_online (summons_month,thirdparty_response_count) VALUES
	 ('2024-02-01 00:00:00.000',1),
	 ('2024-03-01 00:00:00.000',1);


CREATE TEMP TABLE expected_stats_unprocessed_responses (
	loc_code varchar(3) NOT NULL,
	unprocessed_count int4 DEFAULT 0 NULL
);
INSERT INTO expected_stats_unprocessed_responses (loc_code,unprocessed_count) VALUES
	 ('415',6);


create TEMP TABLE expected_stats_welsh_online_responses (
	summons_month timestamp(0) NOT NULL,
	welsh_response_count int4 DEFAULT 0 NULL
);
INSERT INTO expected_stats_welsh_online_responses (summons_month,welsh_response_count) VALUES
	 ('2024-02-01 00:00:00.000',3),
	 ('2024-03-01 00:00:00.000',3);


-- inserting the test data
insert into juror_mod.pool (pool_no, return_date, "owner", loc_code, total_no_required) values ('415240301', current_date, '400', '415', '100');

insert into juror_mod.juror (juror_number, last_name, first_name, address_line_1, responded, bureau_transfer_date, excusal_code, date_excused) values 
('1', 'test', 'test', 'test', true, null,null,null),
('2', 'test', 'test', 'test', true, null,null,null),
('3', 'test', 'test', 'test', true, null,null,null),
('4', 'test', 'test', 'test', false, null,null,null),
('5', 'test', 'test', 'test', false, current_date - 1,null,null),
('6', 'test', 'test', 'test', false, null,null,null),
('7', 'test', 'test', 'test', true, null, 'A', current_date),
('8', 'test', 'test', 'test', true, null, 'A', current_date),
('9', 'test', 'test', 'test', true, null, 'A', current_date),
('10', 'test', 'test', 'test', true, null,'B',null),
('11', 'test', 'test', 'test', true, null,'B',null),
('12', 'test', 'test', 'test', true, null,'B',null);

insert into juror_mod.juror_pool (pool_number, juror_number, owner, status, def_date, is_active) values 
('415240301', '1', '400', '1',null, true),
('415240301', '2', '400', '2',null, true),
('415240301', '3', '400', '11',null, true),
('415240301', '4', '415', '3',null, true),
('415240301', '5', '415', '1',null, true),
('415240301', '6', '415', '2',null, true),
('415240301', '7', '415', '5',null, true),
('415240301', '8', '415', '5',null, true),
('415240301', '9', '415', '5',null, true),
('415240301', '10', '415', '7',current_date, true),
('415240301', '11', '415', '7',current_date, true),
('415240301', '12', '415', '7',current_date, true);

insert into juror_mod.juror_response (juror_number, reply_type, deferral_date, deferral_reason, excusal, excusal_reason, staff_login, staff_assignment_date, welsh, processing_status, relationship, date_received) values
('1','Digital', null, null, null, null,'AUTO', current_date - 3, false,'TODO', 'Test relationship', current_date - 7),
('2','Digital', null, null, null, null,'AUTO', current_date - 3, false,'TODO', null, null),
('3','Digital', null, null, null, null,'AUTO', current_date - 3, false,'TODO', null, null),
('4','Digital', null, null, null, null, 'test', null,true,'TODO', null, null),
('5','Digital', null, null, null, null, 'test', null,true,'TODO', null, null),
('6','Digital', null, null, null, null, 'test', null,true,'TODO', null, null),
('7','Paper', null, null,true,'test', 'test', null, false,'TODO', null, null),
('8','Paper', null, null,true,'test', 'test', null, false,'TODO', null, null),
('9','Paper', null, null,true,'test', 'test', null, false,'TODO', null, null),
('10','Paper',current_date,'TEST', null, null, 'test', null, false,'TODO', null, null),
('11','Paper',current_date,'TEST', null, null, 'test', null, false,'TODO', null, null),
('12','Paper',current_date,'TEST', null, null, 'test', null, false,'TODO', null, null);

insert into juror_mod.juror_history (juror_number,date_created,history_code,user_id, pool_number) values
('1', current_date, 'RSUM', 'test', '415240301'),
('1', current_date, 'RESP', 'test', '415240301'),
('4', current_date, 'RSUM', 'test', '415240301'),
('4', current_date, 'RESP', 'test', '415240301'),
('5', current_date, 'RSUM', 'test', '415240301'),
('5', current_date, 'RESP', 'test', '415240301'),
('6', current_date, 'RSUM', 'test', '415240301'),
('7', current_date, 'RSUM', 'test', '415240301'),
('7', current_date, 'RESP', 'test', '415240301'),
('8', current_date, 'RSUM', 'test', '415240301'),
('8', current_date, 'RESP', 'test', '415240301'),
('9', current_date, 'RSUM', 'test', '415240301'),
('9', current_date, 'RESP', 'test', '415240301');


call juror_mod.refresh_stats_data(6);

-- check results
select case when count(*) 
	 = 0 then 'PASS' else 'FAIL' end as "Stats Response Times Validation"
from (
	select  summons_month, response_month, response_period, loc_code, response_method, response_count from juror_mod.stats_response_times except select summons_month, response_month, response_period, loc_code, response_method, response_count from expected_stats_response_times
);

select case when count(*) 
	 = 0 then 'PASS' else 'FAIL' end as "Stats Auto Processed Validation"
from (
	select processed_date, processed_count from juror_mod.stats_auto_processed except select processed_date, processed_count  from expected_stats_auto_processed
);

select case when count(*) 
	 = 0 then 'PASS' else 'FAIL' end as "Stats Deferrals Validation"
from (
	select bureau_or_court, exec_code, calendar_year, financial_year, "week", excusal_count from juror_mod.stats_deferrals  except select bureau_or_court, exec_code, calendar_year, financial_year, "week", excusal_count  from expected_stats_deferrals
);

select case when count(*) 
	 = 0 then 'PASS' else 'FAIL' end as "Stats Excusals Validation"
from (
	select bureau_or_court, exec_code, calendar_year, financial_year, "week", excusal_count from juror_mod.stats_excusals sap  except select bureau_or_court, exec_code, calendar_year, financial_year, week, excusal_count from expected_stats_excusals
);

select case when count(*) 
	 = 0 then 'PASS' else 'FAIL' end as "Stats Not responded Validation"
from (
	select summons_month, loc_code, non_responsed_count from juror_mod.stats_not_responded  except select summons_month, loc_code, non_responsed_count  from expected_stats_not_responded
);

select case when count(*) 
	 = 0 then 'PASS' else 'FAIL' end as "Stats Response Times Validation"
from (
	select summons_month, response_month, response_period, loc_code, response_method, response_count from juror_mod.stats_response_times  except select summons_month, response_month, response_period, loc_code, response_method, response_count  from expected_stats_response_times
);

select case when count(*) 
	 = 0 then 'PASS' else 'FAIL' end as "Stats Thirdparty online Validation"
from (
	select summons_month, thirdparty_response_count from juror_mod.stats_thirdparty_online  except select summons_month, thirdparty_response_count  from expected_stats_thirdparty_online
);

select case when count(*) 
	 = 0 then 'PASS' else 'FAIL' end as "Stats Unprocessed Responses Validation"
from (
	select loc_code, unprocessed_count from juror_mod.stats_unprocessed_responses except select loc_code, unprocessed_count  from expected_stats_unprocessed_responses
);

select case when count(*) 
	 = 0 then 'PASS' else 'FAIL' end as "Stats Welsh Online Responses Validation"
from (
	select summons_month, welsh_response_count from juror_mod.stats_welsh_online_responses except select summons_month, welsh_response_count from expected_stats_welsh_online_responses
);

drop table expected_stats_auto_processed;
drop table expected_stats_deferrals;
drop table expected_stats_excusals;
drop table expected_stats_not_responded;
drop table expected_stats_response_times;
drop table expected_stats_thirdparty_online;
drop table expected_stats_unprocessed_responses;
drop table expected_stats_welsh_online_responses;
