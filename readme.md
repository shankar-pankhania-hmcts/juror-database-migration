# Note - need to set up environment variables for database username and password if running locally
export ORACLE_USERNAME=....
export ORACLE_PASSWORD=....
export POSTGRES_USERNAME=....
export POSTGRES_PASSWORD=....


# How to setup the Postgresql database (Dev Environment)

You'll need to make sure that you have a PAT (Personal Access Token) generated, to make one you'll need to click on your profile picture
in the top right and click on preferences; then click on access tokens.

From there you'll want to make sure that the following tickboxes are selected:

* read_registry
* write_registry

Once you have generated your PAT, make sure to keep the generated token credentials safe as you'll need it to access the container registry.

Then run the following command:

```
docker login gitlab-registry.clouddev.online
```

If it prompts you for your username and your username is already there (in brackets), then you can hit enter and enter the PAT token credentials otherwise you'll need to enter your gitlab username, and then enter your PAT token credential.

After that, run the following command to pull the image from gitlab:

```
docker image pull gitlab-registry.clouddev.online/juror-digital/moj-juror/oracle-to-postgressql-migration/juror_mod_postgres
```

Then to spin up a container run the following command:

```
docker run --name juror_postgres -d -p 5432:5432 --env PGDATA=/data/ gitlab-registry.clouddev.online/juror-digital/moj-juror/oracle-to-postgressql-migration/juror_mod_postgres
```
NOTE: If the command fails due to the container already existing then you'll need to change the name of the container or remove the container and recreate it.
WARNING: Make sure to baseline the image after creating and also re-creating the juror-mod database.


If you need to bind a folder to create/restore database images then follow the steps below:

you'll need to create the directory first if it doesn't exist you can use finder to create the folder or the mkdir command:
```
mkdir <path>
```

then run the following command:
```
docker run -v <path>:/dump --name juror_postgres -d -p 5432:5432 --env PGDATA=/data/ gitlab-registry.clouddev.online/juror-digital/moj-juror/oracle-to-postgressql-migration/juror_mod_postgres
```

whilst the container is starting and the database is loading you can setup a db connection under DBeaver.

* click on the plug with a plus icon in the top left
* select the PostgreSQL database connection
* it will ask you to select a driver, select PostgreSQL JDBC Driver
  
Set the following values for the rest of the properties:

* Host - localhost
* database - e.g juror
* port - 5432
* username - <username>
* password - <password>

press ok and try to connect the database, and if successful you should be able to browse the database using DBeaver.

You can also use PSQL to connect to the database by running the following command:

Inside the container:
```
psql -U <username> <database>
```

outside the container:
```
psql -U <username> -h <localhost/ipaddress of machine> <database>
```

If you're running this inside the container you won't be prompted for the password as it uses a trust policy, but if asked, then enter the password
and hit enter and you should be connected to the database.
# How to run the migration tool

### NOTE - only need to run if you want to migrate an existing database to a new postgres db

## Docker setup
Open up the terminal and run the following commands:

```
docker build -t ora2pg .
cd docker-compose/ora2pg
docker-compose up -d
```

This will spin up the ora2pg docker container which has all of the dependicies and also ora2pg prebuilt. Postgres database (latest version) will also get spun up for testing usage, if you don't need the postgres database container then just comment it out from the docker-compose.yaml file

## Postgres Note (Container/machine)
You will need to run the scripts in the db-init-scripts, the docker container has been setup to run the scripts automatically but you'll need to run them manually on the postgres flexible server.

## Connection String Config 
You will need to change the ORACLE_DSN config inside of the schema migration config folder. Make sure the details are correct for the oracle database and save the changes, you shouldn't need to change anything else in the file.

## Accessing Container and Running Import Script
Once you've done that, you'll want to go into the ora2pg container by using the following command:

```
docker exec -it ora2pg /bin/bash
```

Once you're in the container you'll want to change directory to the schema you'll want to import:

```
cd /app/migration/\<Schema> e.g. JUROR
```

You will want to edit the config file located in the config folder and edit the following lines:

```
ORACLE_DSN	dbi:Oracle:host=<ip address of oracle db>;sid=xe;port=1521
Note - username and password are provided via the ENV VARs

PG_DSN		dbi:Pg:dbname=juror;host=<ip address of postgres db>;port=5432
Note - username and password are provided via the ENV VARs

You need to set the PGPASSWORD environment variable in order for the import script to stop you prompting for the password every step, in order to do this run the following:
```

```
export PGPASSWORD=\<Password of postgres database>
```

you can get the password for the docker container inside of the docker-compose.yaml file

To run the migration execute the following script using this command:

```
./import_all.sh -d \<database name> -U \<database super user> -o \<same user> -h \<IP address of postgres machine> -y

```

This script will import the schema (including functions etc) plus data.

Once completed you should have a migrated schema into the postgres database.

## Data Migration via file
Currently the existing script (import_all.sh) will connect both databases up and will do the transfer across the network, the other option is to dump the data into a sql file and import the sql file using psql into the postgres database.

To dump the data to sql files instead of a direct connection you'll need to run the following command (inside the ora2pg container):

```
cd /app/migration/\<schema name>/data
ora2pg -t COPY -c ../config/ora2pg.conf
```

After doing this you'll end up with a folder full of sql scripts copy this folder onto the machine running (or if you're running docker then volume bind the folder to your container) and use psql to execute the output.sql file inside of the data folder:

```
psql -U <username> -d <database> -a -f <path to data>/output.sql
```

If prompted for a password, enter the password for the user and hit enter and it should start importing the data

# Migration Reports (Ora2PG)

# Issues with migration

## JUROR Schema

## JUROR_DIGITAL Schema

## JUROR_DIGITAL_USER Schema

## HK (Housekeeping) Schema
* housekeeping_write_params_to_log_package.sql - utl_file
* housekeeping_fetch_parameters_package - makes call to above 
* housekeeping_initate_log_package.sql - l_file is not a known variable also utl_file call
* housekeeping_close_log_package.sql - utl_file
* housekeeping_record_internal_log_start_package.sql - l_seq not known variable - todo with global var config
* housekeeping_write_child_rowcounts_package.sql - utl file
* housekeeping_write_footer_package.sql - utl file
* housekeeping_row_counts_juror_package.sql - "l_part_hist" is not a known variable - todo with global var config
* housekeeping_check_time_expired_package.sql - utl file
* housekeeping_delete_audit_report_package.sql - utl file
* housekeeping_delete_part_hist_package.sql - utl file
* housekeeping_delete_part_expenses_package.sql - utl file
* housekeeping_delete_cert_lett_package - utl file
* housekeeping_delete_disq_lett_package - utl file
* housekeeping_delete_manuals_package - utl file
* housekeeping_delete_confirm_lett_package  - utl file
* housekeeping_delete_part_amendments_package - utl file
* housekeeping_delete_def_lett_package - utl file
* housekeeping_delete_def_denied_package - utl file
* housekeeping_delete_defer_dbf_package - utl file
* housekeeping_delete_undeliver_package - utl file
* housekeeping_delete_exc_lett_package - utl file
*
*
*
*
*
*
*
*


# Data Validation
Needs invesitgation - will be updated shortly


# Ora2Pg - Notes
This section is just notes I have taken throughout the project capturing snippets of things whilst developing the proof of concept

[Ora2pg Documentation](https://ora2pg.darold.net/documentation.html)

### Generate Migration Project
```
ora2pg --project_base \<project base dir> --init_project \<project name>
e.g. ora2pg --project_base /app/migration --init_project JUROR
```

### Config
```
ORACLE_HOME	/opt/instant_client_12_2 - this is where the instant client lives
ORACLE_DSN	dbi:Oracle:host=172.17.0.5;sid=xe;port=1521 - This is the connection string
ORACLE_USER	$ORACLE_USERNAME
ORACLE_PWD $ORACLE_PASSWORD
USER_GRANTS	0 - This has been set to zero to grab the existing users from the oracle DB
DEBUG		1 - Can set this optionally to zero but was useful to see what the tool was doing
```
### export_schema.sh

### import_all.sh

