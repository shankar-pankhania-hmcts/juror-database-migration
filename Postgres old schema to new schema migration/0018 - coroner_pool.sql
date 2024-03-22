/*
 * 
 * +---------------+---------------+---------------------+---------------+---------------------+
 * | Script Number | Source Schema |    Source Table     | Target Schema |    Target Table     |
 * +---------------+---------------+---------------------+---------------+---------------------+
 * | 0018a         | juror         | coroner_pool        | juror_mod     | coroner_pool        |
 * | 0018b         | juror         | coroner_pool_detail | juror_mod     | coroner_pool_detail |
 * +---------------+---------------+---------------------+---------------+---------------------+
 * 
 * coroner_pool
 * ------------
 */


delete from juror_mod.migration_log where script_number like '0018%';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0018a', 'juror', 'coroner_pool', 'juror_mod', 'coroner_pool');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.coroner_pool),
		expected_target_count = (select count(distinct cor_pool_no) from juror.coroner_pool)
where 	script_number = '0018a';

do $$

begin

alter table juror_mod.coroner_pool 
	drop constraint if exists coroner_pool_loc_code_fk;

alter table juror_mod.coroner_pool_detail 
	drop constraint if exists coroner_pool_detail_pool_no_fk;

truncate table juror_mod.coroner_pool;

with target
as
(
	insert into juror_mod.coroner_pool(cor_pool_no,cor_name,cor_court_loc,cor_request_dt,cor_service_dt,cor_no_requested)
	select distinct
		cp.cor_pool_no,
		cp.cor_name,
		cp.cor_court_loc,
		cp.cor_request_dt,
		cp.cor_service_dt,
		cp.cor_no_requested
	from juror.coroner_pool cp
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0018a';


alter table juror_mod.coroner_pool 
	add constraint coroner_pool_loc_code_fk foreign key (cor_court_loc) references juror_mod.court_location(loc_code) not valid;

alter table juror_mod.coroner_pool_detail 
	add constraint coroner_pool_detail_pool_no_fk foreign key (cor_pool_no) references juror_mod.coroner_pool(cor_pool_no) not valid;


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0018a';
	
end $$;

-- coroner_pool_detail

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0018b', 'juror', 'coroner_pool_detail', 'juror_mod', 'coroner_pool_detail');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.coroner_pool_detail),
		expected_target_count = (select count(distinct part_no) from juror.coroner_pool_detail)
where 	script_number = '0018b';

do $$

begin
	
alter table juror_mod.coroner_pool_detail 
	drop constraint if exists coroner_pool_detail_pk;
	
alter table juror_mod.coroner_pool_detail 
	drop constraint if exists coroner_pool_detail_pool_no_fk;

truncate table juror_mod.coroner_pool_detail;

with target as (
	insert into juror_mod.coroner_pool_detail(cor_pool_no,juror_number,title,first_name,last_name,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode)
	select 	cpd.cor_pool_no,
			cpd.part_no,
			cpd.title,
			cpd.fname,
			cpd.lname,
			cpd.address1,
			cpd.address2,
			cpd.address3,
			cpd.address4,
			cpd.address5||case when coalesce(cpd.address6,'') <> '' then ', '||cpd.address6 end as address5,
			cpd.postcode
	from juror.coroner_pool_detail cpd
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0018b';


alter table juror_mod.coroner_pool_detail 
	add constraint coroner_pool_detail_pk primary key (cor_pool_no, juror_number);

alter table juror_mod.coroner_pool_detail 
	add constraint coroner_pool_detail_pool_no_fk foreign key (cor_pool_no) references juror_mod.coroner_pool(cor_pool_no);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0018b';
	
end $$;

end $$;


-- verify results
select * from juror_mod.migration_log where script_number like '0018%' order by script_number;
select * from juror_mod.coroner_pool limit 10;
select * from juror_mod.coroner_pool_detail limit 10;