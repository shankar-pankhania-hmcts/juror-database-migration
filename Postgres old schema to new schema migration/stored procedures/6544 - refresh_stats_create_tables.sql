create table if not exists juror_mod.stats_auto_processed (
                                                    processed_date timestamp(0) not null,
                                                    processed_count int4 null default 0,
                                                    constraint stats_auto_processed_pkey primary key (processed_date)
);


create table if not exists juror_mod.stats_deferrals (
                                               bureau_or_court varchar(6) not null,
                                               exec_code varchar(1) not null,
                                               calendar_year varchar(4) not null,
                                               financial_year varchar(7) not null,
                                               week varchar(7) not null,
                                               excusal_count int4 not null,
                                               constraint stats_deferrals_pkey primary key (bureau_or_court, exec_code, calendar_year, financial_year, week)
);

create table if not exists juror_mod.stats_excusals (
                                              bureau_or_court varchar(6) not null,
                                              exec_code varchar(1) not null,
                                              calendar_year varchar(4) not null,
                                              financial_year varchar(7) not null,
                                              week varchar(7) not null,
                                              excusal_count int4 not null,
                                              constraint stats_excusals_pkey primary key (bureau_or_court, exec_code, calendar_year, financial_year, week)
);


create table if not exists juror_mod.stats_not_responded (
                                                   summons_month timestamp(0) not null,
                                                   loc_code varchar(3) not null,
                                                   non_responsed_count int4 null default 0,
                                                   constraint stats_not_responded_pkey primary key (summons_month, loc_code)
);

create table if not exists juror_mod.stats_response_times (
                                                    summons_month timestamp(0) not null,
                                                    response_month timestamp(0) not null,
                                                    response_period varchar(15) not null,
                                                    loc_code varchar(3) not null,
                                                    response_method varchar(13) not null,
                                                    response_count int4 null default 0,
                                                    constraint stats_response_times_pkey primary key (summons_month, response_month, response_period, loc_code, response_method)
);

create table if not exists juror_mod.stats_thirdparty_online (
                                                       summons_month timestamp(0) not null,
                                                       thirdparty_response_count int4 null default 0,
                                                       constraint stats_thirdparty_online_pkey primary key (summons_month)
);

create table if not exists juror_mod.stats_unprocessed_responses (
                                                           loc_code varchar(3) not null,
                                                           unprocessed_count int4 null default 0,
                                                           constraint stats_unprocessed_responses_pkey primary key (loc_code)
);

create table if not exists juror_mod.stats_welsh_online_responses (
                                                            summons_month timestamp(0) not null,
                                                            welsh_response_count int4 null default 0,
                                                            constraint stats_welsh_online_responses_pkey primary key (summons_month)
);