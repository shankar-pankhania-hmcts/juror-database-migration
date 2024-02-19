/*
 * Task 5516: Develop migration script for the CONTENT_STORE table
 * 
 * CONTENT_STORE
 * -------------
 * 
 */

truncate table juror_mod.content_store restart IDENTITY cascade;

with rows
AS
(
	insert into juror_mod.content_store(request_id,document_id,date_on_q_for_send,file_type,date_sent,data)
	select  cs.request_id,
			cs.document_id,
			cs.date_on_q_for_send,
			cs.file_type,
			cs.date_sent,
			cs.data
	from juror.content_store cs
	returning 1
)
select COUNT(*) from rows;  -- rows updated

-- verify results
select count(*) from juror.content_store;
select * from juror_mod.content_store limit 10;

