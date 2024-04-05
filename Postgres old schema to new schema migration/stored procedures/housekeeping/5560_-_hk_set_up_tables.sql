CREATE TABLE juror_mod.hk_run_log (
	seq_id BIGSERIAL NOT NULL,
	start_time timestamp(0) NULL,
	end_time timestamp(0) NULL,
	jurors_deleted numeric(38) NULL,
	jurors_error numeric(38) NULL,
	CONSTRAINT pk_hk_un_log PRIMARY KEY (seq_id)
);


CREATE TABLE juror_mod.hk_audit (
	seq_id BIGSERIAL NOT NULL,
	juror_number varchar(9) not null, 
	selected_date timestamp null,
	deletion_date date null,
	deletion_summary text null,
	CONSTRAINT pk_hk_audit PRIMARY KEY (seq_id)
);

update hk.hk_params 
set description = 'Data age threshold in days', value = 2557, last_updated = now()
where key = 1;

update hk.hk_params 
set description = 'Digital Data age threshold in days', value = 365, last_updated = now()
where key = 2;

update hk.hk_params 
set value = 10, last_updated = now()
where key = 3;
