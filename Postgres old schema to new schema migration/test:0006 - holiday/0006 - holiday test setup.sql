delete from juror.holidays;

insert into juror.holidays (owner, holiday, description) values
-- 3 bank holidays for 5 primary court locations
('415', '2024-01-01', 'New Years Day'),
('435', '2024-01-01', 'New Years Day'),
('457', '2024-01-01', 'New Years Day'),
('454', '2024-01-01', 'New Years Day'),
('416', '2024-01-01', 'New Years Day'),
('415', '2024-12-25', 'Christmas Day'),
('435', '2024-12-25', 'Christmas Day'),
('457', '2024-12-25', 'Christmas Day'),
('454', '2024-12-25', 'Christmas Day'),
('416', '2024-12-25', 'Christmas Day'),
('415', '2024-12-26', 'Boxing Day'),
('435', '2024-12-26', 'Boxing Day'),
('457', '2024-12-26', 'Boxing Day'),
('454', '2024-12-26', 'Boxing Day'),
('416', '2024-12-26', 'Boxing Day'),
 
-- 2 additional non-working days for 5 primary court locations
('415', '2024-04-04', 'Maintenance work'),
('415', '2024-04-05', 'Maintenance work'),
('416', '2024-04-05', 'Maintenance work'),
('416', '2024-04-06', 'Maintenance work'),
('435', '2024-04-05', 'Maintenance work'),
('435', '2024-04-06', 'Maintenance work'),
('457', '2024-04-05', 'Maintenance work'),
('457', '2024-04-06', 'Maintenance work'),
('454', '2024-04-05', 'Maintenance work'),
('454', '2024-04-06', 'Maintenance work');