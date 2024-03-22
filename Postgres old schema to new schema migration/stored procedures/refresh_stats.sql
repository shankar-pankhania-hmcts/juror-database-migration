-- entry point
create or replace procedure juror_mod.refresh_stats_data(no_of_months int)
language plpgsql
as
$$
declare 
begin
  call juror_mod.auto_processed();
  call juror_mod.response_times_and_non_respond (no_of_months);
  call juror_mod.unprocessed_responses();
  call juror_mod.welsh_online_responses(no_of_months);
  call juror_mod.thirdparty_online(no_of_months);
  call juror_mod.excusals(no_of_months);
  call juror_mod.deferrals(no_of_months);
end;
$$;


/**
Populated the stats_auto_processed table, runs 7 days a week and uses max processed date to figure out the last date processed.
No insertion of rows for days that have no  AUTO processed responses
Digital responses only.
**/
create or replace procedure juror_mod.auto_processed()
language plpgsql
as
$$
declare
	v_text_var1 TEXT;
   	v_text_var2 TEXT;
   	v_text_var3 TEXT;
	l_Job_Type	varchar(50);
begin
l_Job_Type := 'refresh_stats_data.auto_processed';

    insert into juror_mod.stats_auto_processed
      (select r.staff_assignment_date processed_date, count(1) count
      from juror_mod.juror_response r
      where r.staff_login = 'AUTO'
      and r.staff_assignment_date >
         (select coalesce(max(processed_date),'01-JAN-1990') from juror_mod.stats_auto_processed)
      and r.staff_assignment_date < current_date
      and r.reply_type = 'Digital'
      group by r.staff_assignment_date);

    commit;

  	exception when others then

        get stacked diagnostics v_text_var1 = message_text,
                                v_text_var2 = pg_exception_detail,
                                v_text_var3 = pg_exception_hint;
        raise notice '%', 'auto process failed - error:->' || v_text_var1 || '|' || v_text_var2 || '|' || v_text_var3;
       rollback;
end;
$$;


-- Populates JUROR_MOD.STATS_NOT_RESPONDED and JUROR_MOD.STATS_RESPONSE_TIMES
-- used by the Juror Digital performance dashboard
-- Populating both tables in a single transacton so that they are always consistant with each other
-- Replaces the latest n months of summons counts as specified by the no_of_months input parameter
-- It is recommended to use use no_of_months = 6
--    * It needs to be at least 3 given jurors are summoned 9 weeks in advance of their atttendance date
--    * Using 6 allows some contingency in case it is decided to summon jurors earlier
create or replace procedure juror_mod.response_times_and_non_responded(no_of_months int)
language plpgsql
as
$$
declare
    v_text_var1 TEXT;
   	v_text_var2 TEXT;
   	v_text_var3 TEXT;
	  l_Job_Type	varchar(50); 
begin
    l_Job_Type := 'refresh_stats_data.response_times_and_non_respond';

    call juror_mod.not_responded (no_of_months);
    call juror_mod.response_times (no_of_months);
    
    commit;
  	exception when others then
    get stacked diagnostics v_text_var1 = message_text,
                            v_text_var2 = pg_exception_detail,
                            v_text_var3 = pg_exception_hint;
    raise notice '%', 'response times and non responses failed - error:->' || v_text_var1 || '|' || v_text_var2 || '|' || v_text_var3;
    rollback;
end;
$$;

-- Populates JUROR_MOD.STATS_UNPROCESSED_RESPONSES used by the Juror Digital performance dashboard
create or replace procedure juror_mod.unprocessed_responses()
language plpgsql
as
$$
declare 
    v_text_var1 TEXT;
   	v_text_var2 TEXT;
   	v_text_var3 TEXT;
	  l_Job_Type	varchar(50); 
begin
    l_Job_Type := 'refresh_stats_data.unprocessed_responses';
     -- delete then insert
   delete from juror_mod.stats_unprocessed_responses; -- not using truncate table as we want to commit after the insert
   insert into juror_mod.stats_unprocessed_responses
   (select jp.loc_code, count(1)
    from juror_mod.juror_pool jp, juror_mod.juror_response r
    where p.is_active = 'Y'
    and r.juror_number = jp.juror_number
    and r.processing_status = 'TODO'
    and r.reply_type = 'Digital'
    group by jp.loc_code);

    commit;
  	exception when others then
    get stacked diagnostics v_text_var1 = message_text,
                            v_text_var2 = pg_exception_detail,
                            v_text_var3 = pg_exception_hint;
    raise notice '%', 'unprocessed responses failed - error:->' || v_text_var1 || '|' || v_text_var2 || '|' || v_text_var3;
    rollback;
end;
$$;

  -- Populates JUROR_MOD.STATS_WELSH_ONLINE_RESPONSES used by the Juror Digital performance dashboard
  -- number of summons by month summons issued, status and welsh flag
  --        Get date of summons from juror_history
  -- Replaces the latest n months of summons months as specified by the no_of_months input parameter
create or replace procedure juror_mod.welsh_online_responses(no_of_months int)
language plpgsql
as
$$
declare 
    v_text_var1 text;
   	v_text_var2 text;
   	v_text_var3 text;
	  l_job_type	varchar(50); 
begin
    l_job_type := 'refresh_stats_data.welsh_online_responses';
    
    MERGE INTO JUROR_MOD.STATS_WELSH_ONLINE_RESPONSES t
    using (
        select date_trunc('MONTH', h1.date_created) summons_month, count(1) welsh_response_count
        from juror_mod.juror_response r, juror_mod.juror_history h1
        where h1.juror_number = r.juror_number
        and h1.history_code = 'RSUM'
        and h1.date_created > current_date - (no_of_months || ' MONTH')::interval -- exclude jurors summoned more than n months ago
        and r.welsh is TRUE
        and r.reply_type = 'Digital'
        group by date_trunc('MONTH', h1.date_created)) m
    ON ( t.summons_month = m.summons_month)
      WHEN MATCHED THEN
           UPDATE SET t.welsh_response_count = m.welsh_response_count
      WHEN NOT MATCHED then
           INSERT (t.summons_month,t.welsh_response_count)
           VALUES (m.summons_month,m.welsh_response_count);
    
    commit;
  	exception when others then
    get stacked diagnostics v_text_var1 = message_text,
                            v_text_var2 = pg_exception_detail,
                            v_text_var3 = pg_exception_hint;
    raise notice '%', 'welsh_online_responses failed - error:->' || v_text_var1 || '|' || v_text_var2 || '|' || v_text_var3;
    rollback;
end;
$$;

  -- Populates juror_mod.stats_thirdparty_online used by the Juror Digital performance dashboard
  -- number of third party respones by month summons issued
  -- gets date of summons from part_hist
  -- Replaces the latest n months of summons months as specified by the no_of_months input parameter
create or replace procedure juror_mod.thirdparty_online(no_of_months int)
language plpgsql
as
$$
declare 
    v_text_var1 text;
   	v_text_var2 text;
   	v_text_var3 text;
	  l_job_type	varchar(50); 
begin
    l_job_type := 'refresh_stats_data.thirdparty_online';
    
    MERGE INTO JUROR_MOD.STATS_THIRDPARTY_ONLINE t
    using (
        select trunc(h1.date_created,'MONTH') summons_month, count(1) thirdparty_response_count
        from juror_mod.juror_response r, juror_mod.juror_history h1
        where h1.juror_number = r.juror_number
        and h1.history_code = 'RSUM'
        and h1.date_created > current_date - (no_of_months || ' MONTH')::interval  -- exclude jurors summoned more than n months ago
        and r.relationship is not null
        and r.reply_type = 'Digital'
        group by date_trunc('MONTH', h1.date_created)) m
    ON ( t.summons_month = m.summons_month)
      WHEN MATCHED THEN
           UPDATE SET t.thirdparty_response_count = m.thirdparty_response_count
      WHEN NOT MATCHED then
           INSERT (t.summons_month,t.thirdparty_response_count)
           VALUES (m.summons_month,m.thirdparty_response_count);
    
    commit;
  	exception when others then
      get stacked diagnostics v_text_var1 = message_text,
                            v_text_var2 = pg_exception_detail,
                            v_text_var3 = pg_exception_hint;
      raise notice '%', 'thirdparty_online failed - error:->' || v_text_var1 || '|' || v_text_var2 || '|' || v_text_var3;
    rollback;
end;
$$;

-- Populates juror_mod.stats_not_responded used by the Juror Digital performance dashboard

-- Replaces the latest n months of summons counts as specified by the no_of_months input parameter

-- It is recommended to use use no_of_months = 6
--    * It needs to be at least 3 given jurors are summoned 9 weeks in advance of their atttendance date
--    * Using 6 allows some contingency in case it is decided to summon jurors earlier

-- Using delete then insert rather than merge due to the need to identify and delete rows that no longer have a non responded count

-- Tables used:
--      Juror_mod.juror j               Used to get the disqualified from selection indicator from the juror record i.e. summons_file
--      Juror_mod.juror_pool jp         Used to get the loc_code from the juror record
--      Juror_mod.juror_history h1      Used to get the summons date
--      Juror_mod.juror_history h2      Used to get the responded date if no entry in juror_response i.e. first event after the summons/reminders
--                                      Chosen to not to rely on pool.status to indicated responded as incomplete responses may still show as Summoned.
--                                      13/3/24 Will be no need to use juror_history for this once no longer refreshing data migrated from Heritage
--      Juror_mod.juror_response r      Online responses plus paper responses but the latter only from the go-live date for Juror Modernisation
--      Juror_mod.pool p                Used to get a list of pool numbers to enable index on pool table to be used
create or replace procedure juror_mod.not_responded(no_of_months int)
language plpgsql
as
$$
declare 
    v_text_var1 TEXT;
   	v_text_var2 TEXT;
   	v_text_var3 TEXT;
	  l_Job_Type	varchar(50); 
begin
    l_Job_Type := 'refresh_stats_data.not_responded';

   delete from JUROR_MOD.STATS_NOT_RESPONDED where summons_month >= date_trunc('MONTH', (current_date - no_of_months || ' months'::interval));

   INSERT INTO JUROR_MOD.STATS_NOT_RESPONDED(
    select date_trunc('MONTH', s.summons_date) summons_month,
       s.loc_code,
       count(1) Non_Responded_Count
       from (
            select substr(h1.pool_number,1,3) loc_code,  -- JDB-5346 see comments above
            jp.juror_number,
            case 
              when r.juror_number is null then 'Paper'
              when r.reply_type = 'Digital' then 'Online'
              else 'Paper'
            end "Method",
            r.date_received response_date, -- digital plus paper responses but the latter is only those receieved post Juror Modernisation go_live
            min(h1.date_created) summons_date,
            min(h2.date_created) processed_date
            from juror_mod.juror j 
            join juror_mod.juror_pool jp
            on jp.juror_number = j.juror_number
            join juror_mod.juror_history h1
            on h1.juror_number = j.juror_number
            and h1.history_code = "RSUM"
            full outer join juror_mod.juror_history h2
            on h2.juror_number = jp.juror_number
            and h2.history_code <> 'RSUM' -- ignore summons
            and h2.history_code <> 'RNRE' -- ignore reminder letters
            and h2.history_code <> 'PUND' -- Fix for JDB-4621: Undeliverable event is not a response to the summons
            and h2.history_code <> 'PREA' -- JDB-5349 : ignore the pool reasignment
            and h2.history_code <> 'RSUP' -- JDB-5374 : ignore summons reprinted
            full outer join juror_mod.juror_response r
            on r.juror_number = j.juror_number
            where jp.pool_number in (select p.pool_number from juror_mod.pool p where p.return_date >= current_date - (no_of_months || ' MONTH')::interval)
            and jp.is_active = 'Y' -- JDB-5346 see comments above
            and j.juror_number = jp.juror_number
            and (j.summons_file is null or j.summons_file <> 'Disq. on selection')
            and h1.juror_number = jp.juror_number
            and h1.date_created > current_date - (no_of_months || ' MONTH')::interval  -- exclude jurors summoned more than n months ago
            and r.juror_number = jp.juror_number
            group by substr(h1.pool_number,1,3), jp.juror_number,
            case 
              when r.juror_number is null then 'Paper'
              when r.reply_type = 'Digital' then 'Online'
              else 'Paper'
            end,
            r.date_received
            order by jp.juror_number
            ) 
       where coalesce(response_date, processed_date) is null -- exclude responded jurors
       group by date_trunc('MONTH', s.summons_date), 
       case 
              when r.juror_number is null then 'Paper'
              when r.reply_type = 'Digital' then 'Online'
              else 'Paper'
            end,
       abs(coalesce(response_date, processed_date) - summons_date),
       s.loc_code, s.method
       );
    
    commit;
  	exception when others then
    get stacked diagnostics v_text_var1 = message_text,
                            v_text_var2 = pg_exception_detail,
                            v_text_var3 = pg_exception_hint;
    raise notice '%', 'not_responded failed - error:->' || v_text_var1 || '|' || v_text_var2 || '|' || v_text_var3;
    rollback;
end;
$$;

  -- Populates JUROR_MOD.STATS_RESPONSE_TIMES used by the Juror Digital performance dashboard
  -- Replaces the latest n months of summons months as specified by the no_of_months input parameter
  -- It is recommended to use use no_of_months = 6
  --    * It needs to be at least 3 given jurors are summoned 9 weeks in advance of their atttendance date
  --    * Using 6 allows some contingency in case it is decided to summon jurors earlier

create or replace procedure juror_mod.response_times(no_of_months int)
language plpgsql
as
$$
declare 
    v_text_var1 text;
   	v_text_var2 text;
   	v_text_var3 text;
	  l_job_type	varchar(50); 
begin
    l_job_type := 'refresh_stats_data.stats_response_times';
    
    MERGE INTO JUROR_MOD.STATS_RESPONSE_TIMES t
  using (
       select date_trunc('MONTH', s.summons_date) summons_month,
       date_trunc('MONTH', coalesce(response_date, processed_date)) response_month, 
    	 case when abs(coalesce(response_date, processed_date) - summons_date) < 8 then 'Within 7 days'
    		    when abs(coalesce(response_date, processed_date) - summons_date) < 15 then 'Within 14 days'
    		    when abs(coalesce(response_date, processed_date) - summons_date) < 22 then 'Within 21 days'
    		    else 'Over 21 days'
    	 end "caseResponse_Period",
       s.loc_code,
       s.method Response_Method,
       count(1) Response_Count
       from (
            select substr(h1.pool_number,1,3) loc_code,  -- JDB-5346 see comments above
            jp.juror_number,
            case 
              when r.juror_number is null then 'Paper'
              when r.reply_type = 'Digital' then 'Online'
              else 'Paper'
            end "Method",
            r.date_received response_date, -- digital plus paper responses but the latter is only those receieved post Juror Modernisation go_live
            min(h1.date_created) summons_date,
            min(h2.date_created) processed_date
            from juror_mod.juror j
            join juror_mod.juror_pool jp
            on jp.juror_number = j.juror_number
            join juror_mod.juror_history h1
            on h1.juror_number = j.juror_number
            and h1.history_code = 'RSUM'
            full outer join juror_mod.juror_history h2
            on h2.juror_number = j.juror_number
            and h2.history_code <> 'RSUM' -- ignore summons
            and h2.history_code <> 'RNRE' -- ignore reminder letters
            and h2.history_code <> 'PUND' -- Fix for JDB-4621: Undeliverable event is not a response to the summons
            and h2.history_code <> 'PREA' -- JDB-5349 : ignore the pool reasignment
            and h2.history_code <> 'RSUP' -- JDB-5374 : ignore summons reprinted
            and h2.user_id <> 'SYSTEM' -- filter out system generated excusals for covid19
            full outer join juror_mod.juror_response r
            on r.juror_number = jp.juror_number
            where jp.pool_number in (select p.pool_number from juror_mod.pool p where p.return_date >= current_date - (no_of_months || ' MONTH')::interval)
            and jp.is_active = 'Y' -- JDB-5346 see comments above
            and (j.summons_file is null or j.summons_file <> 'Disq. on selection')
            and h1.date_created > current_date - (no_of_months || ' MONTH')::interval -- exclude jurors summoned more than n months ago
            group by substr(h1.pool_number,1,3), jp.juror_number,
            case 
              when r.juror_number is null then 'Paper'
              when r.reply_type = 'Digital' then 'Online'
              else 'Paper'
            end,
            r.date_received
            order by jp.juror_number
            ) s
       where coalesce(response_date, processed_date) is not null -- exclude non responded
       group by trunc(s.summons_date,'MONTH'), 
       date_trunc('MONTH', coalesce(response_date, processed_date)),
       case when abs(coalesce(response_date, processed_date) - summons_date) < 8 then 'Within 7 days'
    		    when abs(coalesce(response_date, processed_date) - summons_date) < 15 then 'Within 14 days'
    		    when abs(coalesce(response_date, processed_date) - summons_date) < 22 then 'Within 21 days'
    		    else 'Over 21 days'
    	 end,
       s.loc_code, s.method
        ) m
  ON ( t.summons_month = m.summons_month and t.RESPONSE_MONTH = m.RESPONSE_MONTH and t.RESPONSE_PERIOD = m.RESPONSE_PERIOD
     and t.LOC_CODE = m.LOC_CODE and t.RESPONSE_METHOD = m.RESPONSE_METHOD)
      WHEN MATCHED THEN
           UPDATE SET t.response_count = m.response_count
      WHEN NOT MATCHED then
           INSERT (t.SUMMONS_MONTH, t.RESPONSE_MONTH, t.RESPONSE_PERIOD, t.LOC_CODE, t.RESPONSE_METHOD, t.RESPONSE_COUNT)
           VALUES (m.SUMMONS_MONTH, m.RESPONSE_MONTH, m.RESPONSE_PERIOD, m.LOC_CODE, m.RESPONSE_METHOD, m.RESPONSE_COUNT);
    
    commit;
  	exception when others then
    get stacked diagnostics v_text_var1 = message_text,
                            v_text_var2 = pg_exception_detail,
                            v_text_var3 = pg_exception_hint;
    raise notice '%', 'response_times failed - error:->' || v_text_var1 || '|' || v_text_var2 || '|' || v_text_var3;
    rollback;
end;
$$;


-- Populates JUROR_MOD.STATS_EFERRALS used by the Juror Digital performance dashboard
-- Replaces the latest n months of deferral stats as specified by the no_of_months input parameter
-- It is recommended to use no_of_months = 12 to allow for deletion of deferrals
-- Using delete then insert rather than merge due to the need to identify and delete rows that no longer have an deferral count due to deletion of the deferral
create or replace procedure juror_mod.deferrals(no_of_months int)
language plpgsql
as
$$
declare 
    v_text_var1 TEXT;
   	v_text_var2 TEXT;
   	v_text_var3 TEXT;
	l_Job_Type	varchar(50); 
begin
    l_Job_Type := 'refresh_stats_data.deferrals';
    delete from juror_mod.stats_deferrals sd where sd.week >= to_char(date_trunc('IW', current_date - no_of_months),'IYYY/IW');

    INSERT INTO juror_mod.stats_deferrals

        (
          Select 
            case when jp.owner = '400' then 'Bureau'
            else 'Court'
            end "Bureau_or_Court",
          coalesce(jp.deferral_code,'O'), -- default to O if null (allowing for inconsistent data in the pool table)
          to_char(p.return_date,'IYYY') Calendar_Year,
          case when p.return_date < to_date('01-APR-'||to_char(p.return_date,'YYYY'),'DD-MON-YYYY') then (to_number(to_char(p.return_date,'YYYY'),'9999')-1)||'/'||to_char(p.return_date,'YY')
              else to_char(p.return_date,'YYYY')||'/'||(to_number(to_char(p.return_date,'YY'),'9999')+1) 
          end "Fin_Year",
          to_char(p.return_date,'IYYY/IW') Week,
          count(1)
          from juror_mod.juror_pool jp, juror_mod.pool p
          where jp.status = 7
          and jp.pool_number = p.pool_number
          and p.return_date >= date_trunc('IW',current_date - (no_of_months || ' MONTH')::interval) -- from the start of the week after deducting the no_of_months
          group by case when jp.owner = '400' then 'Bureau'
            else 'Court'
            end,
          coalesce(jp.deferral_code,'O'),
          to_char(p.return_date,'IYYY'),
          case when p.return_date < to_date('01-APR-'||to_char(p.return_date,'YYYY'),'DD-MON-YYYY') then (to_number(to_char(p.return_date,'YYYY'),'9999')-1)||'/'||to_char(p.return_date,'YY')
              else to_char(p.return_date,'YYYY')||'/'||(to_number(to_char(p.return_date,'YY'),'9999')+1) end,
          to_char(p.return_date,'IYYY/IW'));
      
    commit;
  	exception when others then
    get stacked diagnostics v_text_var1 = message_text,
                            v_text_var2 = pg_exception_detail,
                            v_text_var3 = pg_exception_hint;
    raise notice '%', 'deferrals failed - error:->' || v_text_var1 || '|' || v_text_var2 || '|' || v_text_var3;
    rollback;
end;
$$;






create or replace procedure juror_mod.excusals(no_of_months int)
language plpgsql
as
$$
declare 
    v_text_var1 TEXT;
   	v_text_var2 TEXT;
   	v_text_var3 TEXT;
	l_Job_Type	varchar(50); 
begin
    l_Job_Type := 'refresh_stats_data.excusals';

   delete from juror_mod.stats_excusals where week >= to_char(trunc(add_months(sysdate-1,- no_of_months),'IW'),'IYYY/IW');
          
   INSERT INTO juror_mod.stats_excusals

       (Select case when jp.owner = '400' then 'Bureau'
            else 'Court'
            end "Bureau_or_Court",
        coalesce(j.excusal_code,'O'), -- default to O if null (allowing for inconsistent data in the pool table)
        to_char(p.return_date,'IYYY') Calendar_Year,
        case when p.return_date < to_date('01-APR-'||to_char(p.return_date,'YYYY'),'DD-MON-YYYY') then (to_number(to_char(p.return_date,'YYYY'),'9999')-1)||'/'||to_char(p.return_date,'YY')
             else to_char(p.return_date,'YYYY')||'/'||(to_number(to_char(p.return_date,'YY'),'9999')+1) end Fin_Year,
        to_char(p.return_date,'IYYY/IW') Week,
        count(1)
        from juror_mod.juror_pool jp, juror_mod.pool p, juror_mod.juror j
        where jp.status = 5
        and jp.pool_number = p.pool_number
        and p.return_date >= date_trunc('IW',current_date - (no_of_months || ' MONTH')::interval) -- from the start of the week after deducting the no_of_months
        and jp.is_active = 'Y'
        and j.juror_number = jp.juror_number
        group by case when jp.owner = '400' then 'Bureau'
            else 'Court'
            end,
        coalesce(j.excusal_code,'O'),
        to_char(p.return_date,'IYYY'),
        case when p.return_date < to_date('01-APR-'||to_char(p.return_date,'YYYY'),'DD-MON-YYYY') then (to_number(to_char(p.return_date,'YYYY'),'9999')-1)||'/'||to_char(p.return_date,'YY')
             else to_char(p.return_date,'YYYY')||'/'||(to_number(to_char(p.return_date,'YY'),'9999')+1) end,
        to_char(p.return_date,'IYYY/IW'));
    commit;
  	exception when others then
    get stacked diagnostics v_text_var1 = message_text,
                            v_text_var2 = pg_exception_detail,
                            v_text_var3 = pg_exception_hint;
    raise notice '%', 'unprocessed responses failed - error:->' || v_text_var1 || '|' || v_text_var2 || '|' || v_text_var3;
    rollback;
end;
$$;