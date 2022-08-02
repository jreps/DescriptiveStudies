library(DescriptiveStudies)
library(testthat)

context("DechallengeRechallenge")

test_that("createDechallengeRechallengeSettings", {

  targetIds <- sample(x = 100, size = sample(10, 1))
  outcomeIds <- sample(x = 100, size = sample(10, 1))

  res <- createDechallengeRechallengeSettings(
    targetIds = targetIds,
    outcomeIds = outcomeIds,
    dechallengeStopInterval = 30,
    dechallengeEvaluationWindow = 31
    )

  testthat::expect_true(
    class(res) == 'dechallengeRechallengeSettings'
  )

  testthat::expect_equal(
    res$targetCohortDefinitionIds,
    targetIds
  )

  testthat::expect_equal(
    res$outcomeCohortDefinitionIds,
    outcomeIds
  )

  testthat::expect_equal(
    res$dechallengeStopInterval,
    30
  )

  testthat::expect_equal(
    res$dechallengeEvaluationWindow,
    31
  )

})

test_that("computeDechallengeRechallengeAnalyses", {

  targetIds <- c(2)
  outcomeIds <- c(3,4)

  res <- createDechallengeRechallengeSettings(
    targetIds = targetIds,
    outcomeIds = outcomeIds,
    dechallengeStopInterval = 30,
    dechallengeEvaluationWindow = 30
  )

  dc <- computeDechallengeRechallengeAnalyses(
    connectionDetails = connectionDetails,
    targetDatabaseSchema = 'main',
    targetTable = 'cohort',
    dechallengeRechallengeSettings = res
    )

  testthat::expect_true(class(dc) == 'Andromeda')
  testthat::expect_true(names(dc) == 'dechallengeRechallenge')

  if(actions){ # causing *** caught segfault *** address 0x68, cause 'memory not mapped' zip::zipr

  # test saving/loading
  saveDechallengeRechallengeAnalyses(
    result = dc,
    saveDirectory = file.path(tempdir())
  )

  testthat::expect_true(
    file.exists(file.path(tempdir(), 'DechallengeRechallenge'))
  )

  res2 <- loadDechallengeRechallengeAnalyses(
    saveDirectory = file.path(tempdir())
  )

  testthat::expect_equal(
    nrow(dc$dechallengeRechallenge %>% collect()),
    nrow(res2$dechallengeRechallenge %>% collect())
    )
  }

  # check exporting to csv
  exportDechallengeRechallengeToCsv(
    result = dc,
    saveDirectory = tempdir()
  )

  countN <- dc$dechallengeRechallenge %>%
    dplyr::tally()

  if(!is.null(countN$n)){
    testthat::expect_true(
      file.exists(file.path(
        tempdir(),
        'dechallenge_rechallenge.csv'
      )
      )
    )
  }



})

test_that("computeRechallengeFailCaseSeriesAnalyses", {

  targetIds <- c(1,2)
  outcomeIds <- c(4)

  res <- createDechallengeRechallengeSettings(
    targetIds = targetIds,
    outcomeIds = outcomeIds,
    dechallengeStopInterval = 30,
    dechallengeEvaluationWindow = 31
  )

  dc <- computeRechallengeFailCaseSeriesAnalyses(
    connectionDetails = connectionDetails,
    targetDatabaseSchema = 'main',
    targetTable = 'cohort',
    dechallengeRechallengeSettings = res
  )

  testthat::expect_true(class(dc) == 'Andromeda')
  testthat::expect_true(names(dc) == 'rechallengeFailCaseSeries')

  # test saving/loading
  if(actions){ # causing *** caught segfault *** address 0x68, cause 'memory not mapped' zip::zipr

  saveRechallengeFailCaseSeriesAnalyses(
    result = dc,
    saveDirectory = file.path(tempdir())
  )

  testthat::expect_true(
    file.exists(file.path(tempdir(), 'rechallengeFailCaseSeries'))
  )

  res2 <- loadRechallengeFailCaseSeriesAnalyses(
    saveDirectory = file.path(tempdir())
  )

  testthat::expect_equal(
    nrow(dc$rechallengeFailCaseSeries %>% collect()),
    nrow(res2$rechallengeFailCaseSeries %>% collect())
  )
  }

  # check exporting to csv
  exportRechallengeFailCaseSeriesToCsv(
    result = dc,
    saveDirectory = tempdir()
  )

  countN <- dc$rechallengeFailCaseSeries %>%
    dplyr::tally()

  if(!is.null(countN$n)){
    testthat::expect_true(
      file.exists(file.path(
        tempdir(),
        'rechallenge_fail_case_series.csv'
      )
      )
    )
  }


})
