################################################################################
# INSTRUCTIONS: This script assumes you have cohorts you would like to use in an
# ATLAS instance. Please note you will need to update the baseUrl to match
# the settings for your enviroment. You will also want to change the 
# CohortGenerator::saveCohortDefinitionSet() function call arguments to identify
# a folder to store your cohorts. This code will store the cohorts in 
# "inst/sampleStudy" as part of the template for reference. You should store
# your settings in the root of the "inst" folder and consider removing the 
# "inst/sampleStudy" resources when you are ready to release your study.
# 
# See the Download cohorts section
# of the UsingThisTemplate.md for more details.
# ##############################################################################

library(dplyr)
baseUrl <- "https://atlas-demo.ohdsi.org/WebAPI"
# Use this if your WebAPI instance has security enables
# ROhdsiWebApi::authorizeWebApi(
#   baseUrl = baseUrl,
#   authMethod = "windows"
# )
cohortDefinitionSet <- ROhdsiWebApi::exportCohortDefinitionSet(
  baseUrl = baseUrl,
  cohortIds = c(
    # Exposure 
    1794501, # GLP-1RA
    1794502, # DDP-4 inhibitor
    # outcome
    1794503 # AMI
  ),
  generateStats = TRUE
)

# Rename cohorts
## Exposure
cohortDefinitionSet[cohortDefinitionSet$cohortId == 1794501,]$cohortName <- "GLP-1RA"
cohortDefinitionSet[cohortDefinitionSet$cohortId == 1794502,]$cohortName <- "DDP-4 inhibitor"

## Outcome
cohortDefinitionSet[cohortDefinitionSet$cohortId == 1794503,]$cohortName <- "Acute Myocardial Infarction"



# Re-number cohorts
## Exposure
cohortDefinitionSet[cohortDefinitionSet$cohortId == 1794501,]$cohortId <- 1
cohortDefinitionSet[cohortDefinitionSet$cohortId == 1794502,]$cohortId <- 2

## Outcome
cohortDefinitionSet[cohortDefinitionSet$cohortId == 1794503,]$cohortId <- 3



# Save the cohort definition set
# NOTE: Update settingsFileName, jsonFolder and sqlFolder
# for your study.
CohortGenerator::saveCohortDefinitionSet(
  cohortDefinitionSet = cohortDefinitionSet,
  settingsFileName = "inst/Cohorts.csv",
  jsonFolder = "inst/cohorts",
  sqlFolder = "inst/sql/sql_server",
)


# Download and save the negative control outcomes
negativeControlOutcomeCohortSet <- ROhdsiWebApi::getConceptSetDefinition(
  conceptSetId = 1888552,
  baseUrl = baseUrl
) %>%
  ROhdsiWebApi::resolveConceptSet(
    baseUrl = baseUrl
  ) %>%
  ROhdsiWebApi::getConcepts(
    baseUrl = baseUrl
  ) %>%
  rename(outcomeConceptId = "conceptId",
         cohortName = "conceptName") %>%
  mutate(cohortId = row_number() + 1000) %>%
  select(cohortId, cohortName, outcomeConceptId)

# NOTE: Update file location for your study.
CohortGenerator::writeCsv(
  x = negativeControlOutcomeCohortSet,
  file = "inst/negativeControlOutcomes.csv",
  warnOnFileNameCaseMismatch = F
)




