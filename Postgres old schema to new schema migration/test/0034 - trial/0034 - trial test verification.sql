create temporarcreate temporary table if not exists temp_trial (
	trial_number varchar(16) NOT NULL,
	loc_code varchar(3) NOT NULL,
	description varchar(50) NOT NULL,
	courtroom int8 NOT NULL,
	judge int8 NOT NULL,
	trial_type varchar(3) NOT NULL,
	trial_start_date date NULL,
	trial_end_date date NULL,
	anonymous bool NULL,
	juror_requested int2 NULL,
	jurors_sent int2 null);

INSERT INTO temp_trial (trial_number, loc_code, description, courtroom, judge, trial_type, trial_start_date, trial_end_date, anonymous, juror_requested, jurors_sent) VALUES('T100000000', '794', 'TEST DEFENDANT', 81, 24, 'CIV', '2024-03-26', '2024-03-26', false, NULL, NULL);
INSERT INTO temp_trial (trial_number, loc_code, description, courtroom, judge, trial_type, trial_start_date, trial_end_date, anonymous, juror_requested, jurors_sent) VALUES('T100000001', '767', 'TEST DEFENDANT', 80, 23, 'CIV', '2024-03-26', NULL, false, NULL, NULL);
INSERT INTO temp_trial (trial_number, loc_code, description, courtroom, judge, trial_type, trial_start_date, trial_end_date, anonymous, juror_requested, jurors_sent) VALUES('T100000002', '427', 'TEST DEFENDANT', 81, 24, 'CIV', '2024-03-26', '2024-03-26', false, NULL, NULL);
INSERT INTO temp_trial (trial_number, loc_code, description, courtroom, judge, trial_type, trial_start_date, trial_end_date, anonymous, juror_requested, jurors_sent) VALUES('T100000003', '415', 'TEST DEFENDANT', 80, 23, 'CIV', '2024-03-26', '2024-03-26', false, NULL, NULL);
INSERT INTO temp_trial (trial_number, loc_code, description, courtroom, judge, trial_type, trial_start_date, trial_end_date, anonymous, juror_requested, jurors_sent) VALUES('T100000004', '427', 'TEST DEFENDANT', 81, 24, 'CIV', '2024-03-26', '2024-03-26', false, NULL, NULL);

select
		trial_number,
		loc_code,
		description,
		courtroom,
		judge,
		trial_type,
		trial_start_date,
		trial_end_date,
		anonymous,
		juror_requested,
		jurors_sent
from	temp_trial

except

select
		trial_number,
		loc_code,
		description,
		courtroom,
		judge,
		trial_type,
		trial_start_date,
		trial_end_date,
		anonymous,
		juror_requested,
		jurors_sent
from	juror_mod.trial;


select
		trial_number,
		loc_code,
		description,
		courtroom,
		judge,
		trial_type,
		trial_start_date,
		trial_end_date,
		anonymous,
		juror_requested,
		jurors_sent
from	juror_mod.trial

except

select
		trial_number,
		loc_code,
		description,
		courtroom,
		judge,
		trial_type,
		trial_start_date,
		trial_end_date,
		anonymous,
		juror_requested,
		jurors_sent
from	temp_trial;