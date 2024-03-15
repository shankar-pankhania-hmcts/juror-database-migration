delete from juror_mod.juror_pool;
delete from juror_mod.pool ;
delete from juror_mod.juror;


insert into juror_mod.pool (pool_no, return_date, "owner", loc_code, total_no_required) values ('1', current_date, '400', '415', '10');

insert into juror_mod.juror (juror_number, last_name, first_name, address_line_1, responded) values 
('1', 'test', 'test', 'test', true),
('2', 'test', 'test', 'test', true),
('3', 'test', 'test', 'test', true),
('4', 'test', 'test', 'test', true),
('5', 'test', 'test', 'test', true);

insert into juror_mod.juror_pool (pool_number, juror_number, owner, status) values 
('1', '1', '400', '1'),
('1', '2', '400', '2'),
('1', '3', '400', '11'),
('1', '4', '400', '3'),
('1', '5', '415', '2');

SELECT 
       row_number() over (order by jp.juror_number),
       jp.*
       from juror_mod.juror_pool AS jp
       join juror_mod.pool p
       on p.pool_no  = jp.pool_number
       join juror_mod.court_location cl
       on p.loc_code = cl.loc_code
       where jp.status IN (1,2,11)
       AND jp.owner = '400';
       
      