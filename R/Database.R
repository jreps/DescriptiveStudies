# @file Database.R
#
# Copyright 2021 Observational Health Data Sciences and Informatics
#
# This file is part of PatientLevelPrediction
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

#' Create an sqlite database connection
#' @description
#' This function creates a connection to an sqlite database
#'
#' @details
#' This function creates a sqlite database and connection
#'
#' @param sqliteLocation    The location of the sqlite database
#'
#' @return
#' Returns the connection to the sqlite database
#'
#' @export
createSqliteDatabase <- function(
  sqliteLocation = tempdir()
){

  sqliteLocation <- file.path(sqliteLocation, 'sqliteCharacterization')

  if(!dir.exists(sqliteLocation )){
    dir.create(sqliteLocation, recursive = T)
  }

connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = 'sqlite',
  server = file.path(sqliteLocation, 'sqlite')
  )
connection <- DatabaseConnector::connect(
  connectionDetails = connectionDetails
  )

return(connection)
}

# move Andromeda to sqlite database
insertAndromedaToDatabase <- function(
  connection,
  databaseSchema,
  tableName,
  andromedaObject,
  tempEmulationSchema,
  bulkLoad = T,
  stringAppendToTables = ''
){

  stringAppendToTables <- paste0(gsub(' ' , '', gsub('_', '', stringAppendToTables)), '_')

  ParallelLogger::logInfo(
    paste0('Inserting Andromeda table into Datbase table ', paste0(stringAppendToTables,tableName))
  )

  Andromeda::batchApply(
    tbl = andromedaObject,
    fun = function(x){
      DatabaseConnector::insertTable(
        connection = connection,
        databaseSchema = databaseSchema,
        tableName = paste0(stringAppendToTables,tableName),
        data = as.data.frame(x %>% dplyr::collect()),
        dropTableIfExists = F,
        createTable = F,
        tempEmulationSchema = tempEmulationSchema,
        bulkLoad = bulkLoad,
        camelCaseToSnakeCase = T
      )
    }
  )

  return(TRUE)
}




#' Create the results tables to store characterization results into a database
#' @description
#' This function executes a large set of SQL statements to create tables that can store results
#'
#' @details
#' This function can be used to create (or delete) Characterization result tables
#'
#' @param conn                         A connection to a database created by using the
#'                                     function \code{connect} in the
#'                                     \code{DatabaseConnector} package.
#' @param resultSchema                 The name of the database schema that the result tables will be created.
#' @param targetDialect                The database management system being used
#' @param deleteExistingTables         If true any existing tables matching the PatientLevelPrediction result tables names will be deleted
#' @param createTables                 If true the PatientLevelPrediction result tables will be created
#' @param stringAppendToTables         A string that appends to the PatientLevelPrediction result tables
#' @param tempEmulationSchema          The temp schema used when the database management system is oracle
#'
#' @return
#' Returns NULL but creates the required tables into the specified database schema.
#'
#' @export
createCharacterizationTables <- function(
  conn,
  resultSchema,
  targetDialect = 'postgresql',
  deleteExistingTables = T,
  createTables = T,
  stringAppendToTables = 'c',
  tempEmulationSchema = getOption("sqlRenderTempEmulationSchema")
){


  if(deleteExistingTables){
    ParallelLogger::logInfo('Deleting existing tables')


    tables <- getResultTables()

    if(stringAppendToTables != ''){
      tables <- paste0(toupper(gsub('_','',gsub(' ','', stringAppendToTables))), '_', tables)
    }

    alltables <- DatabaseConnector::getTableNames(
      connection = conn,
      databaseSchema = resultSchema
    )

    for(tb in tables){
      if(tb %in%alltables){
        sql <- 'TRUNCATE TABLE @my_schema.@table'
        sql <- SqlRender::render(sql,
                                 my_schema = resultSchema,
                                 table=tb)
        sql <- SqlRender::translate(sql, targetDialect = targetDialect,
                                    tempEmulationSchema = tempEmulationSchema)
        DatabaseConnector::executeSql(conn, sql)

        sql <- 'DROP TABLE @my_schema.@table'
        sql <- SqlRender::render(sql,
                                 my_schema = resultSchema,
                                 table=tb)
        sql <- SqlRender::translate(sql, targetDialect = targetDialect,
                                    tempEmulationSchema = tempEmulationSchema)
        DatabaseConnector::executeSql(conn, sql)
      }

    }

  }

  if(createTables){
    ParallelLogger::logInfo('Creating characterization results tables')

    if(stringAppendToTables != ''){
      stringAppendToTables <- paste0(toupper(gsub('_','',gsub(' ','', stringAppendToTables))), '_')
    }


    renderedSql <- SqlRender::loadRenderTranslateSql(
      sqlFilename = "ResultTables.sql",
      packageName = "DescriptiveStudies",
      dbms = targetDialect,
      tempEmulationSchema = tempEmulationSchema,
      my_schema = resultSchema,
      string_to_append = stringAppendToTables
    )

    DatabaseConnector::executeSql(conn, renderedSql)
  }

}

#' Exports all tables in the result database to csv files
#' @description
#' This function extracts the database tables into csv files
#'
#' @details
#' This function extracts the database tables into csv files
#'
#' @param connectionDetails         The connection details to input into the
#'                                     function \code{connect} in the
#'                                     \code{DatabaseConnector} package.
#' @param resultSchema                 The name of the database schema that the result tables will be created.
#' @param targetDialect                The database management system being used
#' @param stringAppendToTables         A string that appends to the PatientLevelPrediction result tables
#' @param tempEmulationSchema          The temp schema used when the database management system is oracle
#' @param saveDirectory                The directory to save the csv results
#'
#' @return
#' csv file per table into the saveDirectory
#'
#' @export
exportDatabaseToCsv <- function(
  connectionDetails,
  resultSchema,
  targetDialect,
  stringAppendToTables,
  tempEmulationSchema = NULL,
  saveDirectory
){

  # connect to result database
  connection <- DatabaseConnector::connect(
    connectionDetails = connectionDetails
    )
  on.exit(DatabaseConnector::disconnect(connection))

  # create the folder to save the csv files
  if(!dir.exists(saveDirectory)){
    dir.create(saveDirectory, recursive = T)
  }

  stringAppendToTables <- paste0(gsub(' ' , '', gsub('_', '', stringAppendToTables)), '_')

  # get the table names using the function in uploadToDatabase.R
  tables <- getResultTables()

  # extract result per table
  for(table in tables){
    sql <- "select * from @resultSchema.@appendtotable@tablename"
    sql <- SqlRender::render(
      sql,
      resultSchema = resultSchema,
      appendtotable = stringAppendToTables,
      tablename = table
    )
    sql <- SqlRender::translate(
      sql = sql,
      targetDialect = targetDialect,
      tempEmulationSchema = tempEmulationSchema)
    result <- DatabaseConnector::querySql(connection, sql)

    # save the results as a csv
    readr::write_excel_csv(
      x = result,
      file = file.path(saveDirectory, paste0(table,'.csv'))
    )
  }

  return(invisible(saveDirectory))
}

getResultTables <- function(){
  return(unique(toupper(
    readr::read_csv(
      system.file(
        'settings', 'resultsDataModelSpecification.csv',
        package = 'DescriptiveStudies'
      )
    )$table_name
  )))
}
