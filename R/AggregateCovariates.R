# Copyright 2022 Observational Health Data Sciences and Informatics
#
# This file is part of Characterization
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Create aggregate covariate study settings
#'
#' @param targetIds   A list of cohortIds for the target cohorts
#' @param outcomeIds  A list of cohortIds for the outcome cohorts
#' @template timeAtRisk
#' @param covariateSettings   An object created using \code{FeatureExtraction::createCovariateSettings}
#'
#' @return
#' A list with the settings
#'
#' @export
createAggregateCovariateSettings <- function(
  targetIds,
  outcomeIds,
  riskWindowStart = 1,
  startAnchor = 'cohort start',
  riskWindowEnd = 365,
  endAnchor = 'cohort start',
  covariateSettings
){

  # check cohortIds is a vector of int/double

  # check outcomeIds is a vector of int/double

  #check TAR

  # create list
  result <- list(
    targetIds = targetIds,
    outcomeIds = outcomeIds,
    riskWindowStart = riskWindowStart,
    startAnchor = startAnchor,
    riskWindowEnd = riskWindowEnd ,
    endAnchor = endAnchor,
    covariateSettings = covariateSettings
  )

  class(result) <- 'aggregateCovariateSettings'
  return(result)
}

#' Compute aggregate covariate study
#'
#' @template ConnectionDetails
#' @param cdmDatabaseSchema The schema with the OMOP CDM data
#' @template TargetOutcomeTables
#' @template TempEmulationSchema
#' @param aggregateCovariateSettings   The settings for the AggregateCovariate study
#' @param databaseId Unique identifier for the database (string)
#' @param runId  Unique identifier for the tar and covariate setting
#'
#' @return
#' The descriptive results for each target cohort in the settings.
#'
#' @export
computeAggregateCovariateAnalyses <- function(
  connectionDetails = NULL,
  cdmDatabaseSchema,
  cdmVersion = 5,
  targetDatabaseSchema,
  targetTable,
  outcomeDatabaseSchema = targetDatabaseSchema, # remove
  outcomeTable =  targetTable,  # remove
  tempEmulationSchema = getOption("sqlRenderTempEmulationSchema"),
  aggregateCovariateSettings,
  databaseId = 'database 1',
  runId = 1
) {

  # check inputs
  start <- Sys.time()

  connection <- DatabaseConnector::connect(
    connectionDetails = connectionDetails
  )
  on.exit(DatabaseConnector::disconnect(connection))

  # select T, O, create TnO, TnOc, Onprior T
  # into temp table #agg_cohorts
  createCohortsOfInterest(
    connection = connection,
    aggregateCovariateSettings,
    targetDatabaseSchema,
    targetTable,
    outcomeDatabaseSchema,
    outcomeTable,
    tempEmulationSchema
  )

  ## get counts
  sql <- 'select cohort_definition_id, count(*) N from #agg_cohorts group by cohort_definition_id;'
  sql <- SqlRender::translate(
    sql = sql,
    targetDialect = connectionDetails$dbms
    )
  counts <- DatabaseConnector::querySql(
    connection = connection,
    sql = sql
  )
  #print(counts) # testing

  message("Computing aggregate covariate results")

  result <- FeatureExtraction::getDbCovariateData(
    connection = connection,
    oracleTempSchema = tempEmulationSchema,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortTable = '#agg_cohorts',
    cohortTableIsTemp = T,
    cohortId = -1,
    covariateSettings = aggregateCovariateSettings$covariateSettings,
    cdmVersion = cdmVersion,
    aggregated = T
  )

  # add databaseId and runId to each table in results
  # could add settings table with this and just have setting id
  # as single extra column?

  for(tableName in names(result)){
    result[[tableName]] <- result[[tableName]] %>%
      dplyr::mutate(
        runId = !!runId,
        databaseId = !!databaseId
      ) %>%
      dplyr::relocate(
        .data$databaseId,
        .data$runId
        )
  }

  # settings:
  # run_id, database_id, covariate_setting_json,
  # riskWindowStart, startAnchor, riskWindowEnd, endAnchor
  # combined_cohort_id, target_cohort_id, outcome_cohort_id,
  # type


  result$settings <- DatabaseConnector::querySql(
    connection = connection,
    sql = SqlRender::translate(
    sql = "
    select distinct
    cohort_definition_id as combined_cohort_id,
    target_id as target_cohort_id,
    outcome_id as outcome_cohort_id,
    cohort_type
    from #target_with_outcome

    union

    select distinct
    cohort_definition_id as combined_cohort_id,
    target_id as target_cohort_id,
    outcome_id as outcome_cohort_id,
    cohort_type
    from #target_nooutcome

    union

    select distinct
    cohort_definition_id + 2 as combined_cohort_id,
    target_id as target_cohort_id,
    outcome_id as outcome_cohort_id,
    'OnT' as cohort_type
    from #target_with_outcome

    union

    select distinct
    cohort_definition_id*100000 as combined_cohort_id,
    cohort_definition_id as target_cohort_id,
    0 as outcome_cohort_id,
    'T' as cohort_type
    from #targets_agg

 union

 select distinct
    cohort_definition_id*100000 as combined_cohort_id,
    0 as target_cohort_id,
    cohort_definition_id as outcome_cohort_id,
    'O' as cohort_type
    from #outcomes_agg
    ;",
    targetDialect = connection@dbms
    ),
    snakeCaseToCamelCase = T
  )

  covariateSettingsJson <- as.character(
    ParallelLogger::convertSettingsToJson(
      aggregateCovariateSettings$covariateSettings
    )
    )

  result$settings <- result$settings %>%
    dplyr::mutate(
      runId = !!runId,
      databaseId = !!databaseId,
      covariateSettingJson = !!covariateSettingsJson,
      riskWindowStart = !!aggregateCovariateSettings$riskWindowStart,
      startAnchor = !!aggregateCovariateSettings$startAnchor,
      riskWindowEnd = !!aggregateCovariateSettings$riskWindowEnd ,
      endAnchor = !!aggregateCovariateSettings$endAnchor
    )

  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "DropAggregateCovariate.sql",
    packageName = "DescriptiveStudies",
    dbms = connection@dbms,
    tempEmulationSchema = tempEmulationSchema
  )
  DatabaseConnector::executeSql(
    connection = connection,
    sql = sql, progressBar = FALSE,
    reportOverallTime = FALSE
  )

  return(result)
}


createCohortsOfInterest <- function(
  connection = connection,
  aggregateCovariateSettings,
  targetDatabaseSchema,
  targetTable,
  outcomeDatabaseSchema,
  outcomeTable,
  tempEmulationSchema
){

  ParallelLogger::logInfo(paste0('connection type ', connection@dbms))

  sql <- SqlRender::loadRenderTranslateSql(
    sqlFilename = "createTargetOutcomeCombinations.sql",
    packageName = "DescriptiveStudies",
    dbms = connection@dbms,
    tempEmulationSchema = tempEmulationSchema,
    target_database_schema = targetDatabaseSchema,
    target_table = targetTable,
    outcome_database_schema = outcomeDatabaseSchema,
    outcome_table = outcomeTable,
    target_ids = paste(aggregateCovariateSettings$targetIds, collapse = ',', sep = ','),
    outcome_ids = paste(aggregateCovariateSettings$outcomeIds, collapse = ',', sep = ','),
    tar_start = aggregateCovariateSettings$riskWindowStart,
    tar_start_anchor = ifelse(aggregateCovariateSettings$startAnchor == 'cohort start', 'cohort_start_date', 'cohort_end_date'),
    tar_end = aggregateCovariateSettings$riskWindowEnd,
    tar_end_anchor = ifelse(aggregateCovariateSettings$endAnchor == 'cohort start', 'cohort_start_date', 'cohort_end_date')
  )

  DatabaseConnector::executeSql(
    connection = connection,
    sql = sql,
    progressBar = FALSE,
    reportOverallTime = FALSE
  )

}
