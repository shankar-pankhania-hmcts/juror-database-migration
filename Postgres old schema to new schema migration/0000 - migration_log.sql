/*
* +---------------+---------------+--------------+---------------+---------------+
* | Script Number | Source Schema | Source Table | Target Schema | Target Table  |
* +---------------+---------------+--------------+---------------+---------------+
* |          0000 | n/a           | n/a          | juror_mod     | migration_log |
* +---------------+---------------+--------------+---------------+---------------+
 * 
 * migrtation_log
 * ---------------
 * 
 */
 
drop table if exists juror_mod.migration_log;

create table juror_mod.migration_log (
    script_number varchar(5) not null,
	source_schema varchar(20) not null,
	source_table varchar(50) not null,
	target_schema varchar(20) not null,
	target_table varchar(50) not null,
	"status" varchar(20),
	source_count int,
	expected_target_count int,
	actual_target_count int,
	start_time timestamp not null default now(),
	end_time timestamp null,
	execution_time interval hour to second null
);