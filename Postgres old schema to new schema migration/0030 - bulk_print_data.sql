/*
 * 
 * +---------------+---------------+--------------+---------------+-----------------+
 * | Script Number | Source Schema | Source Table | Target Schema |  Target Table   |
 * +---------------+---------------+--------------+---------------+-----------------+
 * |          0030 | juror         | print_files  | juror_mod     | bulk_print_data |
 * +---------------+---------------+--------------+---------------+-----------------+
 * 
 * bulk_print_data
 * ---------------
 */

delete from juror_mod.migration_log where script_number = '0030';

insert into juror_mod.migration_log (script_number, source_schema, source_table, target_schema, target_table, start_time)
values ('0030', 'juror', 'print_files', 'juror_mod', 'bulk_print_data', now());


update	juror_mod.migration_log
set		source_count = (select count(1) from juror.print_files),
		expected_target_count = (select count(1) from juror.print_files))
where 	script_number = '0030';

do $$

begin
	
alter table juror_mod.bulk_print_data 
	drop constraint if exists bulk_print_data_fk_form_type;

alter table juror_mod.bulk_print_data 
	drop constraint if exists bulk_print_data_juror_no_fk;

truncate table juror_mod.bulk_print_data restart identity cascade;

with target as (
 	insert into juror_mod.bulk_print_data (juror_no,creation_date,form_type,detail_rec,extracted_flag,digital_comms)
	select distinct 
			pf.part_no,
			pf.creation_date,
			pf.form_type,
			pf.detail_rec,
			case upper(pf.extracted_flag)
				when 'Y' then true
				else false
			end,
			case upper(pf.digital_comms)
				when 'Y' then true
				else false
			end
	from juror.print_files pf
	returning 1
)

update	juror_mod.migration_log
set		actual_target_count = (select count(1) from target),
		"status" = 'COMPLETE',
		end_time = now(),
		execution_time = age(now(), migration_log.start_time)
where 	script_number = '0030';



alter table juror_mod.bulk_print_data 
	add constraint bulk_print_data_fk_form_type foreign key (form_type) references juror_mod.t_form_attr(form_type);

alter table juror_mod.bulk_print_data 
	add constraint bulk_print_data_juror_no_fk foreign key (juror_no) references juror_mod.juror(juror_number);

exception
	when others then
		update	juror_mod.migration_log
		set		"status" = 'ERROR',
				actual_target_count = 0,
				end_time = now(),
				execution_time = age(now(), migration_log.start_time)
		where 	script_number = '0030';
	
end $$;
	
-- verify results
select * from juror_mod.migration_log where script_number = '0030';
select * from juror_mod.bulk_print_data limit 10;