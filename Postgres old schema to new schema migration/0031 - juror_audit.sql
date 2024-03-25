/*
 * 
 * +---------------+---------------+-----------------+---------------+--------------+
 * | Script Number | Source Schema |  Source Table   | Target Schema | Target Table |
 * +---------------+---------------+-----------------+---------------+--------------+
 * |          0031 | juror         | part_amendments | juror_mod     | juror_audit  |
 * +---------------+---------------+-----------------+---------------+--------------+
 * 
 * juror_audit
 * -----------
 */

delete from juror_mod.migration_log where script_number = '0031';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0031', 'juror', 'part_amendments', 'juror_mod', 'juror_audit', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.part_amendments),
		expected_target_count = (select count(1) from (
										select 		part_no, edit_date 
										from 		juror.part_amendments 
										group by 	part_no, edit_date
										
										union
										
										select		part_no, null
										from		juror.pool
										group by 	part_no))
where 	script_number = '0031';

do $$

begin

-- drop constraints (primary key constraint will drop associated index to improve performance)

alter table juror_mod.juror_audit drop constraint if exists juror_audit_pkey;
alter table juror_mod.juror_audit drop constraint if exists fk_revision_number;

	
/* 
 * - Build a temporary table to hold addresses in multiple columns rather than a (long) single line
 * - Each line is identified via a comma
 * - Pivot the results of the address columns into one row per ID
 * - Join to addresses CTE to build data to import
 */

/*
 * Handle the comma separated column of PART_AMENDMENTS prior to copying the data in bulk
 * Due to PART_AMENDMENTS storing the address in a single column (comma separated) we need to define a temporary table to hold the address
*/
create table if not exists temp_addresses(id varchar(200), addressline smallint, address varchar(35));
truncate table temp_addresses;

-- build the table by splitting the comma separated string column - note the need to store the line number for each row 
insert into temp_addresses(id,addressline,address)
select a.id, a.addressline, a.address
from	( 
			select distinct 	pa.part_no||pa.edit_date||pa.address as id, 
								a.nr as addressline,
								ltrim(a.elem) as address
			from 				juror.part_amendments pa
			join 				lateral	unnest(string_to_array(pa.address,',')) with ordinality a(elem, nr) on true
			where 				coalesce(pa.address,'') <> ''
	 	) a;

create extension if not exists tablefunc;


truncate table juror_mod.juror_audit restart identity cascade; 

with juror_changes as (
	-- group together rows for the same juror and edit date
	select distinct
				pa.part_no,
				pa.edit_date,
				max(pa.title) as title,
				max(pa.fname) as fname,
				max(pa.lname) as lname,
				max(pa.dob) as dob,
				max(pa.address) as address,
				max(pa.zip) as zip,
				max(pa.sort_code) as sort_code,
				max(pa.bank_acct_name) as bank_acct_name,
				max(pa.bank_acct_no) as bank_acct_no,
				max(pa.bldg_soc_roll_no) as bldg_soc_roll_no,
				max(p.h_email) as h_email,
				max(p.h_phone) as h_phone,
				max(p.m_phone) as m_phone,
				max(p.w_phone) as w_phone,
				max(p.w_ph_local) as w_ph_local,
				max(a.address1) as address1,
				max(a.address2) as address2,
				max(a.address3) as address3,
				max(a.address4) as address4,
				max(a.address5) as address5
	from 		juror.part_amendments pa
	join 		juror_mod.juror j
	on 			pa.part_no = j.juror_number
	left join 	(
				-- use a pviot to produce a single row for each part_no for the address columns
				select  id,
						address1,
						address2,
						address3,
						address4,
						address5
				from crosstab('select a.id, a.addressline, a.address from temp_addresses a order by 1,2')
				as addr_table (id varchar(200), address1 varchar(35), address2 varchar(35), address3 varchar(35), address4 varchar(35), address5 varchar(35))
			) a
		on 		pa.part_no||pa.edit_date||coalesce(pa.address,'') = a.id
	left join 	juror.pool p
		on 		pa.part_no = p.part_no 
				and pa.pool_no = p.pool_no
				and pa."owner" = p."owner"
	group by 	pa.part_no,
			 	pa.edit_date
),

target as (
	select  nextval('public.rev_info_seq') as revision,
			case 
				when rank() over(partition by a.juror_number order by a.juror_number asc, a.edit_date) = 1
					then 0 -- first insert
					else 1 -- update
			end as rev_type,
			a.edit_date,
			a.juror_number,
			a.title,
			a.fname,
		 	a.lname,
			a.dob,
			a.address_line_1,
			a.address_line_2,
			a.address_line_3,
			a.address_line_4,
			a.address_line_5, 
			a.postcode,
			a.sort_code,
			a.bank_acct_name,
			a.bank_acct_no,
			a.bldg_soc_roll_no,
			a.h_email,
			a.h_phone,
			a.m_phone,
			a.w_phone,
			a.w_ph_local
	from (
			select distinct
					jc.part_no as juror_number,
					jc.edit_date as edit_date,
					case
							when jc.title is null and exists(select 1 from juror_changes jc2 where jc2.title is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
								then (select jc2.title from juror_changes jc2 where jc2.title is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
							when jc.title is null
								then j.title
								else jc.title
					end as title,
					case
						when jc.fname is null  and exists(select 1 from juror_changes jc2 where jc2.fname is not null and jc2.edit_date > jc.edit_date  and jc2.part_no = jc.part_no)
							then (select jc2.fname from juror_changes jc2 where jc2.fname is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.fname is null 
							then j.first_name
							else jc.fname
					end as fname,
					case
						when jc.lname is null  and exists(select 1 from juror_changes jc2 where jc2.lname is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
							then (select jc2.lname from juror_changes jc2 where jc2.lname is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.lname is null 
							then j.last_name
							else jc.lname
					end as lname,
					case
						-- when null or set to 1901-01-01 with later amendments then set to next amendment record - if date is 1901-01-01 then set to null
						when coalesce(jc.dob,'1901-01-01') = '1901-01-01' and exists(select 1 from juror_changes jc2 where jc2.dob is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
							then (select case when jc2.dob = '1901-01-01' then null else jc2.dob end from juror_changes jc2 where jc2.dob is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						-- when null or set to 1901-01-01 but no later amendments then set to current juror record
						when coalesce(jc.dob,'1901-01-01') = '1901-01-01' and not exists(select 1 from juror_changes jc2 where jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
							then j.dob
						-- otherwise if set to 1901-01-01 then set to null
						when jc.dob = '1901-01-01'
							then null
							else jc.dob
					end as dob,
					case
						when jc.address1 is null and exists(select 1 from juror_changes jc2 where jc2.address1 is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
							then (select jc2.address1 from juror_changes jc2 where jc2.address1 is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.address1 is null 
							then j.address_line_1
							else jc.address1
					end as address_line_1,
					case
						when jc.address2 is null and exists(select 1 from juror_changes jc2 where jc2.address2 is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
							then (select jc2.address2 from juror_changes jc2 where jc2.address2 is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.address2 is null 
							then j.address_line_2
							else jc.address2
					end as address_line_2,
					case
						when jc.address3 is null and exists(select 1 from juror_changes jc2 where jc2.address3 is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
							then (select jc2.address3 from juror_changes jc2 where jc2.address3 is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.address3 is null 
							then j.address_line_3
							else jc.address3
					end as address_line_3,
					case
						when jc.address4 is null and exists(select 1 from juror_changes jc2 where jc2.address4 is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
							then (select jc2.address4 from juror_changes jc2 where jc2.address4 is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.address4 is null 
							then j.address_line_4
							else jc.address4
					end as address_line_4,
					case
						when jc.address5 is null and exists(select 1 from juror_changes jc2 where jc2.address5 is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
							then (select jc2.address5 from juror_changes jc2 where jc2.address5 is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.address5 is null 
							then j.address_line_5
							else jc.address5
					end as address_line_5,
					case
						when jc.zip is null  and exists(select 1 from juror_changes jc2 where jc2.zip is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
							then (select jc2.zip from juror_changes jc2 where jc2.zip is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.zip is null 
							then j.postcode
							else jc.zip
					end as postcode,
					case
						when jc.sort_code is null and exists(select 1 from juror_changes jc2 where jc2.sort_code is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
							then (select jc2.sort_code from juror_changes jc2 where  jc2.sort_code is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.sort_code is null 
							then j.sort_code
							else jc.sort_code
					end as sort_code,
					case
						when jc.bank_acct_name is null and exists(select 1 from juror_changes jc2 where jc2.bank_acct_name is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
							then (select jc2.bank_acct_name from juror_changes jc2 where jc2.bank_acct_name is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.bank_acct_name is null 
							then j.bank_acct_name
							else jc.bank_acct_name
					end as bank_acct_name,
					case
						when jc.bank_acct_no is null and exists(select 1 from juror_changes jc2 where jc2.bank_acct_no is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
							then (select jc2.bank_acct_no from juror_changes jc2 where jc2.bank_acct_no is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.bank_acct_no is null 
							then j.bank_acct_no
							else jc.bank_acct_no
					end as bank_acct_no,
					case
						when jc.bldg_soc_roll_no is null and exists(select 1 from juror_changes jc2 where jc2.bldg_soc_roll_no is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no)
							then (select jc2.bldg_soc_roll_no from juror_changes jc2 where jc2.bldg_soc_roll_no is not null and jc2.edit_date > jc.edit_date and jc2.part_no = jc.part_no limit 1)
						when jc.bldg_soc_roll_no is null 
							then j.bldg_soc_roll_no
							else jc.bldg_soc_roll_no
					end as bldg_soc_roll_no,
					case
						when jc.h_email is null 
							then j.h_email
							else jc.h_email
					end as h_email,
					case
						when jc.h_phone is null 
							then j.h_phone
							else jc.h_phone
					end as h_phone,
					case
						when jc.m_phone is null 
							then j.m_phone
							else jc.m_phone
					end as m_phone,
					case
						when jc.w_phone is null 
							then j.w_phone
							else jc.w_phone
					end as w_phone,
					case
						when jc.w_ph_local is null 
							then j.w_ph_local
							else jc.w_ph_local
					end as w_ph_local
			from juror_changes jc
			join juror_mod.juror j
			on jc.part_no = j.juror_number
			
			union
			
			select 	j.juror_number,
					j.last_update as edit_date,
					j.title,
					j.first_name,
					j.last_name,
					j.dob,
					j.address_line_1,
					j.address_line_2,
					j.address_line_3,
					j.address_line_4,
					j.address_line_5,
					j.postcode,
					j.sort_code,
					j.bank_acct_name,
					j.bank_acct_no,
					j.bldg_soc_roll_no,
					j.h_email,
					j.h_phone,
					j.m_phone,
					j.w_phone,
					j.w_ph_local
			from 	juror_mod.juror j
			order by 1,2
		) a
),

rev_info as  (
	insert into juror_mod.rev_info(revision_number,revision_timestamp)
	select revision, cast(extract(epoch from edit_date) as integer) 
	from target 
)

-- create the audit records and increment the sequence by merging data with later changes and if none then from juror table where amendment column is null 
insert into juror_mod.juror_audit (revision,rev_type,juror_number,title,first_name,last_name,dob,address_line_1,address_line_2,address_line_3,address_line_4,address_line_5,postcode,h_email,bank_acct_name,bank_acct_no,bldg_soc_roll_no,sort_code,h_phone,m_phone,w_phone,w_ph_local)
select  r.revision,
		r.rev_type,
		r.juror_number,
		r.title,
		r.fname,
	 	r.lname,
		r.dob,
		r.address_line_1,
		r.address_line_2,
		r.address_line_3,
		r.address_line_4,
		r.address_line_5, 
		r.postcode,
		r.sort_code,
		r.bank_acct_name,
		r.bank_acct_no,
		r.bldg_soc_roll_no,
		r.h_email,
		r.h_phone,
		r.m_phone,
		r.w_phone,
		r.w_ph_local
from target r;

-- remove the temporary table
drop table if exists temp_addresses;

-- enable any foreign keys prior to deleting any previous data in the new schema
alter table juror_mod.juror_audit add constraint fk_revision_number 
	foreign key (revision) references juror_mod.rev_info(revision_number);

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from juror_mod.juror_audit),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0031';

-- re-enable the primary key 
alter table juror_mod.juror_audit add constraint juror_audit_pkey 
	primary key (revision, juror_number);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0031';
	
end $$;
	
-- verify results
select * from juror_mod.migration_log where script_number = '0031';
select * from juror_mod.juror_audit limit 10;
select max(revision) from juror_mod.juror_audit;	-- check last id value in new table
select last_value from rev_info_seq;				-- check last id value in sequence table