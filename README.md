DescriptiveStudies
================

Introduction
============
DescriptiveStudies is an R package for performing characterization of a target and a comparator cohort.

Features
========
- Compute incidence rates
- Compute time to event
- ...

Examples
========

```r
targetOutcomes <- data.frame(targetId = 1, comparatorId = 2)


# Connection is a DatabaseConnector connection:
result <- computeIncidenceRates(connection = connection,
                                targetDatabaseSchema = "main",
                                targetTable = "cohort",
                                comparatorDatabaseSchema = "main",
                                comparatorTable = "cohort",
                                targetOutcomes = targetOutcomes,
                                riskWindowStart = 0,
                                startAnchor = "cohort start",
                                riskWindowEnd = 0,
                                endAnchor = "cohort end")
```

Technology
============
Characterization is an R package.

System Requirements
============
Requires R (version 4.0.0 or higher). Libraries used in Characterization require Java.

Installation
=============
1. See the instructions [here](https://ohdsi.github.io/Hades/rSetup.html) for configuring your R environment, including Java.

2. In R, use the following commands to download and install Characterization:

  ```r
  install.packages("remotes")
  remotes::install_github("jreps/DescriptiveStudies")
  ```

User Documentation
==================
Documentation can be found on the [package website](https://jreps.github.io/DescriptiveStudies).

Contributing
============
Read [here](https://ohdsi.github.io/Hades/contribute.html) how you can contribute to this package.

