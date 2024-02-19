/*
 * Task 5549: Develop migration script for the password_export_placeholders table
 * 
 * PASSWORD_EXPORT_PLACEHOLDERS
 * ----------------------------
 * 
 */

TRUNCATE TABLE juror_mod.password_export_placeholders;

WITH rows
AS
(
	insert into juror_mod.password_export_placeholders(owner,login,placeholder_name,use)
	select DISTINCT 
			pep.owner,
			pep.login,
			pep.placeholder_name,
			pep.use
	from juror.password_export_placeholders pep
	RETURNING 1
)
SELECT COUNT(*) FROM rows;

select count(*) from juror.password_export_placeholders;
select * from juror_mod.password_export_placeholders limit 10;
