CREATE TABLE @my_schema.@string_to_appendtime_to_event (
    database_id int NOT NULL,
    target_cohort_definition_id bigint NOT NULL,
    outcome_cohort_definition_id bigint NOT NULL,
    outcome_type varchar(20) NOT NULL,
    target_outcome_type varchar(20) NOT NULL,
    time_to_event int NOT NULL,
    num_events int NOT NULL,
    time_scale varchar(20) NOT NULL
);

CREATE TABLE @my_schema.@string_to_appendrechallenge_fail_case_series (
    --run_id,
    database_id int NOT NULL,
    dechallenge_stop_interval int,
    dechallenge_evaluation_window int,
    target_cohort_definition_id bigint NOT NULL,
    outcome_cohort_definition_id bigint NOT NULL,
    subject_id bigint NOT NULL,
    first_exposure_number int NOT NULL,
    first_exposure_start_date date NOT NULL,
    first_exposure_end_date date NOT NULL,
    first_outcome_number int NOT NULL,
    first_outcome_start_date date NOT NULL,
    rechallenge_exposure_number int NOT NULL,
    rechallenge_exposure_start_date date NOT NULL,
    rechallenge_exposure_end_date date NOT NULL,
    rechallenge_outcome_number int NOT NULL,
    rechallenge_outcome_start_date date NOT NULL
);

CREATE TABLE @my_schema.@string_to_appenddechallenge_rechallenge (
    database_id int NOT NULL,
    dechallenge_stop_interval int,
    dechallenge_evaluation_window int,
    target_cohort_definition_id bigint NOT NULL,
    outcome_cohort_definition_id bigint NOT NULL,
    num_exposure_eras int NOT NULL,
    num_persons_exposed int NOT NULL,
    num_cases int,
    dechallenge_attempt int,
    dechallenge_fail int,
    dechallenge_success int,
    rechallenge_attempt int,
    rechallenge_fail int,
    rechallenge_success int,
    pct_dechallenge_attempt float,
    pct_dechallenge_success float,
    pct_dechallenge_fail float,
    pct_rechallenge_attempt float,
    pct_rechallenge_success float,
    pct_rechallenge_fail float
);


-- covariateSettings
CREATE TABLE @my_schema.@string_to_appendsettings (
    run_id int NOT NULL,
    database_id varchar(10),
    covariate_setting_json varchar(MAX),
    risk_window_start int,
    start_anchor varchar(15),
    risk_window_end int,
    end_anchor varchar(15),
    combined_cohort_id int,
    target_cohort_id int,
    outcome_cohort_id int,
    cohort_type varchar(10)
);

CREATE TABLE @my_schema.@string_to_appendanalysis_ref (
    run_id int NOT NULL,
    database_id int NOT NULL,
    analysis_id int NOT NULL,
    analysis_name varchar(max) NOT NULL,
    domain_id varchar(30) NOT NULL,
    start_day int,
    end_day int,
    is_binary varchar(1),
    missing_means_zero varchar(1)
);

CREATE TABLE @my_schema.@string_to_appendcovariate_ref (
    run_id int NOT NULL,
    database_id int NOT NULL,
    covariate_id int NOT NULL,
    covariate_name varchar(max) NOT NULL,
    analysis_id int NOT NULL,
    concept_id int
);

CREATE TABLE @my_schema.@string_to_appendcovariates (
    run_id int NOT NULL,
    database_id int NOT NULL,
    cohort_definition_id int NOT NULL,
    covariate_id int NOT NULL,
    sum_value int NOT NULL,
    average_value float NOT NULL
);

CREATE TABLE @my_schema.@string_to_appendcovariates_continuous (
    run_id int NOT NULL,
    database_id int NOT NULL,
    cohort_definition_id int NOT NULL,
    covariate_id int NOT NULL,
    count_value int NOT NULL,
    min_value float,
    max_value float,
    average_value float,
    standard_deviation float,
    median_value float,
    p_10_value float,
    p_25_value float,
    p_75_value float,
    p_90_value float
);
