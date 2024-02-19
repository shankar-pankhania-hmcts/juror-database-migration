/*
 * Task: 5215
 * 
 * JUROR_POOL
 * ----------
 * Migrate data from JUROR.POOL into JUROR_MOD.JUROR_POOL
 */



/*
 * Disable any foreign keys prior to deleting any previous data in the new schema
 * Note that simply disabling the FK on the table will not have any effect due to system tables permissions 
 * so the only option is to remove and then re-add them.
 * 
 */
ALTER TABLE juror_mod.juror_pool
   DROP CONSTRAINT IF EXISTS juror_pool_fk_juror; 

ALTER TABLE juror_mod.juror_pool
   DROP CONSTRAINT IF EXISTS juror_pool_pool_no_fk;
  
TRUNCATE juror_mod.juror_pool;

WITH last_updated as 
(
	-- identify the last record for the juror so that only this one is copied
	select  p.part_no, 
			p.pool_no, 
			MAX(p."owner") as owner,
			MAX(p.last_update) as last_update
	from (
			select  p.part_no, 
					p.pool_no, 
					p."owner",
					p.last_update,
					RANK() OVER (
				    PARTITION BY p.part_no, p.pool_no
				    ORDER BY p.part_no, p.pool_no, p.last_update desc) as ranking -- order by last_updated (oldest first)
			from JUROR.pool p 
			WHERE p.read_only = 'N'
		) p	
	where p.ranking = 1
	group by p.part_no, 
			p.pool_no			 
),
rows AS 
(
	insert into juror_mod.juror_pool(juror_number,pool_number,owner,ret_date,user_edtq,is_active,status,times_sel,def_date,location,no_attendances,no_attended,no_fta,no_awol,pool_seq,edit_tag,next_date,on_call,smart_card,was_deferred,deferral_code,id_checked,postpone,paid_cash,scan_code,last_update,reminder_sent,transfer_date,date_created)
	SELECT distinct 
			p.part_no,
			p.pool_no,
			p.owner,
			p.ret_date,
			p.user_edtq,
			case UPPER(p.is_active)
				when 'Y' 
					then true
					else false
			END,
			CASE p.status WHEN  11 --awaiting info 
				THEN 1 -- summoned
				ELSE p.status
			END,
			p.times_sel,
			p.def_date,
			p.location,
			p.no_attendances,
			p.no_attended,
			p.no_fta,
			p.no_awol,
			p.pool_seq,
			p.edit_tag,
			p.next_date,
			case UPPER(p.on_call)
				when 'Y' 
					then true
					else false
			END,
			p.smart_card,
			case UPPER(p.was_deferred)
				when 'Y' 
					then true
					else false
			END,
			null as deferral_code, -- defined by printed letters additional info
			p.id_checked,
			case UPPER(p.postpone)
				when 'Y' 
					then true
					else false
			END,
			case UPPER(p.paid_cash)
				when 'Y' 
					then true
					else false
			END,
			p.scan_code,
			p.last_update,
			case UPPER(p.reminder_sent)
				when 'Y' 
					then true
					else false
			END,
			p.transfer_date,
			(
				select  ph.last_update
				from
					(
						select  ph.part_no, 
								ph.pool_no, 
								ph."owner",
								ph.last_update,
								RANK() OVER (
							    PARTITION BY ph.part_no, ph.pool_no
							    ORDER BY ph.part_no, ph.pool_no, ph.last_update asc) as ranking -- identify the first record for the juror
						from (
								select distinct 
										ph.part_no, 
										ph.pool_no, 
										ph."owner",
										ph.last_update
							    from JUROR.part_hist ph 
							    where ph.part_no = p.part_no
							    and ph.pool_no = p.pool_no
							    and ph.owner = p.owner
								union 
								select distinct 
										ph.part_no, 
										ph.pool_no, 
										ph."owner",
										ph.last_update
							    from JUROR.pool ph
							    where ph.part_no = p.part_no
							    and ph.pool_no = p.pool_no
							    and ph.owner = p.owner
							) ph
					) ph
				where ph.ranking = 1
			) as date_created
	FROM juror.pool p
	join last_updated lu 
	on p.part_no = lu.part_no
	and p.pool_no = lu.pool_no
	and p."owner" = lu."owner" 
	WHERE p.read_only = 'N'
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected

-- Enable any foreign keys prior to deleting any previous data in the new schema
ALTER TABLE juror_mod.juror_pool 
	ADD CONSTRAINT juror_pool_fk_juror FOREIGN key (juror_number) REFERENCES juror_mod.juror(juror_number) not valid;

ALTER TABLE juror_mod.juror_pool 
	ADD CONSTRAINT juror_pool_pool_no_fk FOREIGN KEY (pool_number) REFERENCES juror_mod.pool(pool_no) NOT valid;

-- verify results
WITH last_updated as 
(
	-- identify the last record for the juror so that only this one is copied
	select  p.part_no, 
			p.pool_no, 
			MAX(p."owner") as owner,
			MAX(p.last_update) as last_update
	from (
			select  p.part_no, 
					p.pool_no, 
					p."owner",
					p.last_update,
					RANK() OVER (
				    PARTITION BY p.part_no, p.pool_no
				    ORDER BY p.part_no, p.pool_no, p.last_update desc) as ranking -- order by last_updated (oldest first)
			from JUROR.pool p 
			WHERE p.read_only = 'N'
		) p	
	where p.ranking = 1
	group by p.part_no, 
			p.pool_no			 
)
SELECT count(*)
FROM juror.pool p
join last_updated lu 
on p.part_no = lu.part_no
and p.pool_no = lu.pool_no
and p."owner" = lu."owner" 
WHERE p.read_only = 'N';

select * FROM juror_mod.juror_pool limit 10;

