/*
 * Task 5298: 
 * 
 * 
 * Migrate data from juror_digital.NOTIFY_TEMPLATE_MAPPING → juror_mod.notify_template_mapping
 * Migrate data from juror_digital.notify_template_field → juror_mod.notify_template_field
 * Migrate data from juror_digital.REGION_NOTIFY_TEMPLATE → juror_mod.region_notify_template
 * 
 */


/*
 * notify_template_mapping
 * -----------------------
 */

truncate table juror_mod.notify_template_mapping;

with rows
as
(
 	INSERT into juror_mod.notify_template_mapping (form_type,notification_type,notify_name,template_id,template_name,version)
	SELECT distinct 
			ntm.form_type,
			ntm.notification_type,
			ntm.notify_name,
			ntm.template_id,
			ntm.template_name,
			ntm.version
	FROM juror_digital.notify_template_mapping ntm
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected

-- verify results
select count(*) FROM juror_digital.notify_template_mapping;
select * FROM juror_mod.notify_template_mapping;

/*
 * notify_template_field
 * ---------------------
 */
truncate table juror_mod.notify_template_field;

with rows
as
(
 	INSERT into juror_mod.notify_template_field (convert_to_date,database_field,field_length,jd_class_name,jd_class_property,position_from,position_to,template_field,template_id,version)
	SELECT distinct 
			case ntf.convert_to_date
				when 'Y'
					then true
					else false
			end as convert_to_date,
			ntf.database_field,
			ntf.field_length,
			ntf.jd_class_name,
			ntf.jd_class_property,
			ntf.position_from,
			ntf.position_to,
			ntf.template_field,
			ntf.template_id,
			ntf.version
	FROM juror_digital.notify_template_field ntf
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected

-- verify results
select count(*) FROM juror_digital.notify_template_field;
select * FROM juror_mod.notify_template_field;


/*
 * region_notify_template
 * ----------------------
 */

truncate table juror_mod.region_notify_template;

with rows
as
(
 	INSERT into juror_mod.region_notify_template (legacy_template_id,message_format,notify_template_id,region_id,region_template_id,template_name,triggered_template_id,welsh_language)
	SELECT distinct 
			rnt.legacy_template_id,
			rnt.message_format,
			rnt.notify_template_id,
			rnt.region_id,
			rnt.region_template_id,
			rnt.template_name,
			rnt.triggered_template_id,
			rnt.welsh_language
	FROM juror_digital.region_notify_template rnt
	RETURNING 1
)
SELECT count(*) FROM rows; -- return the number of rows affected


-- verify results
select count(*) FROM juror_digital.region_notify_template;
select * FROM juror_mod.region_notify_template;
