/*
 * +---------------+---------------+--------------+---------------+--------------+
 * | Script Number | Source Schema | Source Table | Target Schema | Target Table |
 * +---------------+---------------+--------------+---------------+--------------+
 * |          0017 | juror         | pool         | juror_mod     | juror_pool   |
 * +---------------+---------------+--------------+---------------+--------------+
 * 
 * juror_pool
 * ----------
 * 
 */

delete from juror_mod.migration_log where script_number = '0017';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table)
values ('0017', 'juror', 'pool', 'juror_mod', 'juror_pool');


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.pool),
		expected_target_count = (select count(1) from juror.pool where read_only = 'N')
where 	script_number = '0017';

do $$

begin

-- drop indexes to improve performance

drop index if exists juror_mod.i_juror_no;
drop index if exists juror_mod.i_next_date; 
drop index if exists juror_mod.i_pool_no;
  
truncate juror_mod.juror_pool;

with creation_date as (
select		ph.part_no,
			ph.pool_no,
			min(ph.date_part) as date_created
from		juror.part_hist ph
group by	ph.part_no,
			ph.pool_no
)

, target as (
	insert into juror_mod.juror_pool(juror_number,pool_number,"owner",user_edtq,is_active,status,times_sel,def_date,"location",no_attendances,no_attended,no_fta,no_awol,pool_seq,edit_tag,next_date,on_call,smart_card,was_deferred,deferral_code,id_checked,postpone,paid_cash,scan_code,last_update,reminder_sent,transfer_date,date_created)
	select distinct 
				p.part_no,
				p.pool_no,
				p."owner",
				p.user_edtq,
				case upper(p.is_active)
					when 'Y' 
						then true
						else false
				end,
				case p.status when  11 	-- awaiting info is deprecated in the new system
					then 1 				-- migrate as summoned
					else p.status
				end,
				p.times_sel,
				p.def_date,
				p."location",
				p.no_attendances,
				p.no_attended,
				p.no_fta,
				p.no_awol,
				p.pool_seq,
				p.edit_tag,
				p.next_date,
				case upper(p.on_call)
					when 'Y' 
						then true
						else false
				end,
				p.smart_card,
				case upper(p.was_deferred)
					when 'Y' 
						then true
						else false
				end,
				case
					when status = 7 then p.exc_code
					else null
				end as deferral_code,
				p.id_checked,
				case upper(p.postpone)
					when 'Y' 
						then true
						else false
				end,
				case upper(p.paid_cash)
					when 'Y' 
						then true
						else false
				end,
				p.scan_code,
				p.last_update,
				case UPPER(p.reminder_sent)
					when 'Y' 
						then true
						else false
				end,
				p.transfer_date,
				cd.date_created
	from 		juror.pool p
	left join 	creation_date cd
		on		cd.part_no = p.part_no
				and cd.pool_no = p.pool_no
	where 		p.read_only = 'N'
	returning 	1
)

update	juror_mod.migration_log
set		actual_target_count = (select COUNT(1) from target),
		"status" = 'COMPLETE'
where 	script_number = '0017';

create index i_juror_no on juror_mod.juror_pool using btree (juror_number);
create index i_next_date on juror_mod.juror_pool using btree (next_date);
create index i_pool_no on juror_mod.juror_pool using btree (pool_number);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0
		where 	script_number = '0017';

end $$;

select * from juror_mod.migration_log where script_number = '0017';
select * FROM juror_mod.juror_pool limit 10;