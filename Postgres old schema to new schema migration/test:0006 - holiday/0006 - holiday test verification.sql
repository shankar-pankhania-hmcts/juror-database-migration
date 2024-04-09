create temporary table if not exists temp_holiday (
	id bigserial NOT NULL,
	loc_code varchar(3) NULL,
    holiday date NULL,
	description varchar(30) NOT NULL,
    public bool not null);
   
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (1, null, '2024/01/01', 'New Year’s Day', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (2, null, '2024/03/29', 'Good Friday', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (3, null, '2024/04/01', 'Easter Monday', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (4, null, '2024/05/06', 'Early May Bank Holiday', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (5, null, '2024/05/27', 'Spring Bank Holiday', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (6, null, '2024/08/26', 'Summer Bank Holiday', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (7, null, '2024/12/25', 'Christmas Day', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (8, null, '2024/12/26', 'Boxing Day', true);

INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (1, null, '2025/01/01', 'New Year’s Day', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (2, null, '2025/04/18', 'Good Friday', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (3, null, '2025/04/21', 'Easter Monday', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (4, null, '2025/05/05', 'Early May Bank Holiday', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (5, null, '2025/05/26', 'Spring Bank Holiday', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (6, null, '2025/08/25', 'Summer Bank Holiday', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (7, null, '2025/12/25', 'Christmas Day', true);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (8, null, '2025/12/26', 'Boxing Day', true);


INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (9, '415', '2024-04-04', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (10, '415', '2024-04-05', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (11, '767', '2024-04-04', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (12, '767', '2024-04-05', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (13, '462', '2024-04-04', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (14, '462', '2024-04-05', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (15, '416', '2024-04-05', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (16, '416', '2024-04-06', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (17, '435', '2024-04-05', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (18, '435', '2024-04-06', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (19, '457', '2024-04-05', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (20, '457', '2024-04-06', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (21, '761', '2024-04-05', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (22, '761', '2024-04-06', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (23, '756', '2024-04-05', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (24, '756', '2024-04-06', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (25, '454', '2024-04-05', 'Maintenance work', false);
INSERT INTO temp_holiday (id, loc_code, holiday, description, public) values (26, '454', '2024-04-06', 'Maintenance work', false);

select
        loc_code,
        holiday,
		description,
        public
from	temp_holiday

except

select
        loc_code,
        holiday,
		description,
        public
from	juror_mod.holiday;


select
        loc_code,
        holiday,
		description,
        public
from	juror_mod.holiday

except

select
        loc_code,
        holiday,
		description,
        public
from	temp_holiday;