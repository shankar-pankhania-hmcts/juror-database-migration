/*
 * 
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * | 0034a         | juror         | trial        | juror_mod     | trial        |
 * | 0034b         | juror         | panel        | juror_mod     | juror_trial  |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * messages
 * --------
 */

delete from juror_mod.migration_log where script_number like '0034%';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0034a', 'juror', 'trial', 'juror_mod', 'trial', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror.trial),
		expected_target_count = (select count(1) from juror.trial)
where 	script_number = '0034a';

do $$

begin

alter table juror_mod.trial 
	drop constraint if exists trial_judge_fk;

alter table juror_mod.trial 
	drop constraint if exists trial_court_loc_fk;


truncate table juror_mod.juror_trial;
truncate table juror_mod.trial cascade; -- truncates appearance table as well

drop table trial_loc;

create temporary table if not exists trial_loc as (
	select distinct t.trial_no
					,t."owner"
					,u.loc_code
					,u.pool_no
	from			juror.trial as t
	inner join		juror.panel as p
		on			t."owner" = p."owner" 
					and t.trial_no = p.trial_no
	inner join 		juror.part_hist as h
		on			p."owner" = h."owner" 
					and h.part_no = p.part_no 
					and h.other_information = t.trial_no
	inner join 		juror.unique_pool as u
		on			u.pool_no = h.pool_no
					and u."owner" = h."owner"
	where 			h.history_code in ('VCRE', 'VADD', 'TADD')
					and u.read_only = 'N'
					and u.new_request = 'N'
);

with target as (
	insert into juror_mod.trial(trial_number,loc_code,description,courtroom,judge,trial_type,trial_start_date,trial_end_date,anonymous)
	select distinct 
				t.trial_no,
				coalesce(tl.loc_code, t."owner") as loc_code,
				t.descript,
				c.id as courtroom,
				j.id as judge,
				t.t_type,
				t.trial_dte,
				t.trial_end_date,
				case upper(t.anonymous)
					when 'Y'
						then true
						else false
				end as anonymous
	from 		juror.trial t
	inner join 	juror_mod.courtroom c
		on 		t.room_no = c.room_number 
				and t."owner" = c.loc_code
	inner join 	juror_mod.judge j 
		on 		t.judge = j.code 
				and t."owner" = j."owner"
	left join 	trial_loc tl
		on 		t.trial_no = tl.trial_no
				and t."owner" = tl."owner"
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0034a';


alter table juror_mod.trial add constraint trial_judge_fk 
	foreign key (judge) references juror_mod.judge(id); 

alter table juror_mod.trial add constraint trial_court_loc_fk 
	foreign key (loc_code) references juror_mod.court_location(loc_code);


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0034a';

end $$;


-- juror_trial

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0034b', 'juror', 'panel', 'juror_mod', 'juror_trial', now());

update	juror_mod.migration_log
set		source_count = (select count(1) from juror.panel),
		expected_target_count = (select count(1) from juror.panel)
where 	script_number = '0034b';

do $$

begin

alter table juror_mod.juror_trial 
	alter column pool_number drop not null;
	
alter table juror_mod.juror_trial
	drop constraint if exists juror_trial_pk;

with target as (
	insert into juror_mod.juror_trial(loc_code,juror_number,trial_number,pool_number,rand_number,date_selected,result,completed)
	select distinct
				coalesce(tl.loc_code, p."owner") as loc_code,
				p.part_no,
				p.trial_no,
				tl.pool_no,
				p.rand_no,
				p.date_selected,
				p."result",
				case upper(p.complete)
					when 'Y'
						then true
						else false
				end
	from 		juror.panel p
	left join 	trial_loc tl
		on 		p.trial_no = tl.trial_no
				and p."owner" = tl."owner"
	returning 1
)


update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0034b';


alter table juror_mod.juror_trial add constraint juror_trial_pk
	primary key (loc_code,juror_number,trial_number);


exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0034b';
	
end $$;

drop table if exists last_location;
	
-- verify results
select * from juror_mod.migration_log where script_number like '0034%' order by script_number;
select * from juror_mod.trial limit 10;
select * from juror_mod.juror_trial limit 10;