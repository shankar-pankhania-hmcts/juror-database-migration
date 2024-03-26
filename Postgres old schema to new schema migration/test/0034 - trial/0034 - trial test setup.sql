delete from juror.part_hist;
delete from juror.panel;
delete from juror.pool;
delete from juror.unique_pool;
delete from juror.trial;
delete from juror.judge;
delete from juror."location";


-- Dummy test data
insert into juror.judge ("owner", judge, description) values
('427', '1234','Test judge'),
('415', '4321','Judge Test');

insert into juror."location"("owner", "location", description) values
('415', '1', 'large room fits 100 people'),
('427', '2', 'large room fits 100 people');

insert into juror.trial (trial_no, "owner", descript, judge, t_type, trial_dte, trial_end_date, anonymous, room_no) values
('T100000000','427', 'TEST DEFENDANT', '1234','CIV', current_date, current_date, 'N', 2),
('T100000001','415', 'TEST DEFENDANT', '4321','CIV', current_date, null, 'N', 1),
('T100000002','427', 'TEST DEFENDANT', '1234','CIV', current_date, current_date, 'N', 2),
('T100000003','415', 'TEST DEFENDANT', '4321','CIV', current_date, current_date, 'N', 1),
('T100000004','427', 'TEST DEFENDANT', '1234','CIV', current_date, current_date, 'N', 2);

insert into juror.panel ("owner", part_no, trial_no, rand_no, date_selected, "result") values
('427', '042700001', 'T100000000', 1, current_date, 'J'),
('427', '042700002', 'T100000000', 2, current_date, 'J'), -- no pool record
('427', '042700003', 'T100000000', 3, current_date, 'J'),
('415', '041500001', 'T100000001', 1, current_date, 'J'),
('427', '042700004', 'T100000002', 1, current_date, 'J'); -- no history

insert into juror.pool ("owner", part_no, pool_no, lname, fname, address, address4, zip, reg_spc, ret_date, responded) values 
('427', '042700001', '427000001', 'Person', 'Test', 'Address Line 1', 'Address Line 4', 'CH2 2AN', 'R', current_date, 'Y'),
('427', '042700003', '427000001', 'Person', 'Test', 'Address Line 1', 'Address Line 4', 'CH2 2AN', 'R', current_date, 'Y'),
('415', '041500001', '415000001', 'Person', 'Test', 'Address Line 1', 'Address Line 4', 'CH2 2AN', 'R', current_date, 'Y'),
('427', '042700004', '427000002', 'Person', 'Test', 'Address Line 1', 'Address Line 4', 'CH2 2AN', 'R', current_date, 'Y');

insert into juror.unique_pool ("owner", pool_no, return_date, next_date, no_requested, pool_total, reg_spc, pool_type, loc_code, new_request, read_only) values
('427', '427000001', current_date, current_date, 0, 0, 'R', 'CRO', '794', 'N', 'N'),
('427', '427000002', current_date, current_date, 0, 0, 'R', 'CRO', '427', 'N', 'N'),
('415', '415000001', current_date, current_date, 0, 0, 'R', 'CRO', '767', 'N', 'N');

insert into juror.part_hist ("owner", part_no, date_part, history_code, user_id, other_information, pool_no) values
('427', '042700001', current_date - interval '2 weeks', 'VCRE', 'test_user', 'T100000000', '427000001'),
('427', '042700001', current_date - interval '2 weeks', 'VADD', 'test_user', 'T100000000', '427000001'),
('427', '042700003', current_date - interval '2 weeks', 'TADD', 'test_user', 'T100000000', '427000001'),
('415', '041500001', current_date - interval '3 weeks', 'VADD', 'test_user', 'T100000001', '415000001');