################################################################################
# INSTRUCTIONS: Make sure you have downloaded your cohorts using 
# DownloadCohorts.R and that those cohorts are stored in the "inst" folder
# of the project. This script is written to use the sample study cohorts
# located in "inst/sampleStudy" so you will need to modify this in the code 
# below. 
# 
# See the Create analysis specifications section
# of the UsingThisTemplate.md for more details.
# 
# More information about Strategus HADES modules can be found at:
# https://ohdsi.github.io/Strategus/reference/index.html#omop-cdm-hades-modules.
# This help page also contains links to the corresponding HADES package that
# further details.
# ##############################################################################
library(dplyr)
library(Strategus)

########################################################
# Above the line - MODIFY ------------------------------
########################################################

# Get the list of cohorts - NOTE: you should modify this for your
# study to retrieve the cohorts you downloaded as part of
# DownloadCohorts.R
cohortDefinitionSet <- CohortGenerator::getCohortDefinitionSet(
  settingsFileName = "inst/Cohorts.csv",
  jsonFolder = "inst/cohorts",
  sqlFolder = "inst/sql/sql_server"
)

cmTcList <- CohortGenerator::readCsv("inst/cmTcList.csv") # needed to create target-comparator-outcome pairs
excludedCovariateConcepts <- CohortGenerator::readCsv("inst/excludedCovariateConcepts.csv")

# oList <- CohortGenerator::readCsv("inst/oList.csv")
# ncoList <- CohortGenerator::readCsv("inst/negativeControlOutcomes.csv")

# sccsTList <- CohortGenerator::readCsv("inst/sccsTList.csv")
# sccsIList <- CohortGenerator::readCsv("inst/sccsIList.csv")

tcis <- list(
  list(
    targetId = c(
      1
    ), 
    comparatorId = c(
      2
    ), 
    # indicationId = 50, 
    genderConceptIds = c(8507, 8532), # use valid genders (remove unknown)
    minAge = NULL, # All ages In years. Can be NULL
    maxAge = NULL, # All ages In years. Can be NULL
    excludedCovariateConceptIds = excludedCovariateConcepts$conceptId
  ) 
)


outcomes <- tibble(
  cohortId = c(3), 
  cleanWindow = c(rep(9999, 1))
)



# Time-at-risks (TARs) for the outcomes of interest in your study
timeAtRisks <- tibble(
  label = c("On treatment", "On treatment"),
  riskWindowStart  = c(1, 1),
  startAnchor = c("cohort start", "cohort start"),
  riskWindowEnd  = c(0, 0),
  endAnchor = c("cohort end", "cohort end")
)
# Try to avoid intent-to-treat TARs for SCCS, or then at least disable calendar time spline:
# sccsTimeAtRisks <- tibble(
#   label = c("On treatment", "On treatment"),
#   riskWindowStart  = c(1, 1),
#   startAnchor = c("cohort start", "cohort start"),
#   riskWindowEnd  = c(0, 0),
#   endAnchor = c("cohort end", "cohort end")
# )
# # Try to use fixed-time TARs for patient-level prediction:
# plpTimeAtRisks <- tibble(
#   riskWindowStart  = c(1, 1),
#   startAnchor = c("cohort start", "cohort start"),
#   riskWindowEnd  = c(365, 365),
#   endAnchor = c("cohort start", "cohort start"),
# )
# If you are not restricting your study to a specific time window, 
# please make these strings empty
studyStartDate <- '20171201' #YYYYMMDD
studyEndDate <- '20241231'   #YYYYMMDD
# Some of the settings require study dates with hyphens
studyStartDateWithHyphens <- gsub("(\\d{4})(\\d{2})(\\d{2})", "\\1-\\2-\\3", studyStartDate)
studyEndDateWithHyphens <- gsub("(\\d{4})(\\d{2})(\\d{2})", "\\1-\\2-\\3", studyEndDate)


# Consider these settings for estimation  ----------------------------------------

useCleanWindowForPriorOutcomeLookback <- FALSE # If FALSE, lookback window is all time prior, i.e., including only first events
psMatchMaxRatio <- 1 # If bigger than 1, the outcome model will be conditioned on the matched set
maxCohortSizeForFitting <- 250000 # Downsampled example study to 10000
maxCohortSize <- maxCohortSizeForFitting
maxCasesPerOutcome <- 1000000 # Downsampled example study to 10000

# Consider these settings for patient-level prediction  ----------------------------------------
plpMaxSampleSize <- 1000000 # Downsampled example study to 20000

########################################################
# Below the line - DO NOT MODIFY -----------------------
########################################################

# Don't change below this line (unless you know what you're doing) -------------

# Shared Resources -------------------------------------------------------------

# Get the unique subset criteria from the tcis
# object to construct the cohortDefintionSet's 
# subset definitions for each target/comparator
# cohort
# dfUniqueTcis <- data.frame()
# for (i in seq_along(tcis)) {
#   dfUniqueTcis <- rbind(dfUniqueTcis, data.frame(cohortId = tcis[[i]]$targetId,
#                                                  # indicationId = paste(tcis[[i]]$indicationId, collapse = ","),
#                                                  genderConceptIds = paste(tcis[[i]]$genderConceptIds, collapse = ","),
#                                                  minAge = paste(tcis[[i]]$minAge, collapse = ","),
#                                                  maxAge = paste(tcis[[i]]$maxAge, collapse = ",")
#   ))
#   if (!is.null(tcis[[i]]$comparatorId)) {
#     dfUniqueTcis <- rbind(dfUniqueTcis, data.frame(cohortId = tcis[[i]]$comparatorId,
#                                                    # indicationId = paste(tcis[[i]]$indicationId, collapse = ","),
#                                                    genderConceptIds = paste(tcis[[i]]$genderConceptIds, collapse = ","),
#                                                    minAge = paste(tcis[[i]]$minAge, collapse = ","),
#                                                    maxAge = paste(tcis[[i]]$maxAge, collapse = ",")
#     ))
#   }
# }
# 
# dfUniqueTcis <- unique(dfUniqueTcis)
# dfUniqueTcis$subsetDefinitionId <- 0 # Adding as a placeholder for loop below
# dfUniqueSubsetCriteria <- unique(dfUniqueTcis[,-1])
# 
# for (i in 1:nrow(dfUniqueSubsetCriteria)) {
#   uniqueSubsetCriteria <- dfUniqueSubsetCriteria[i,]
#   dfCurrentTcis <- dfUniqueTcis[# dfUniqueTcis$indicationId == uniqueSubsetCriteria$indicationId &
#                                   dfUniqueTcis$genderConceptIds == uniqueSubsetCriteria$genderConceptIds &
#                                   dfUniqueTcis$minAge == uniqueSubsetCriteria$minAge & 
#                                   dfUniqueTcis$maxAge == uniqueSubsetCriteria$maxAge,]
#   targetCohortIdsForSubsetCriteria <- as.integer(dfCurrentTcis[, "cohortId"])
#   dfUniqueTcis[# dfUniqueTcis$indicationId == dfCurrentTcis$indicationId &
#                  dfUniqueTcis$genderConceptIds == dfCurrentTcis$genderConceptIds &
#                  dfUniqueTcis$minAge == dfCurrentTcis$minAge & 
#                  dfUniqueTcis$maxAge == dfCurrentTcis$maxAge,]$subsetDefinitionId <- i
#   
#   subsetOperators <- list()
#   # if (uniqueSubsetCriteria$indicationId != "") {
#   #   subsetOperators[[length(subsetOperators) + 1]] <- CohortGenerator::createCohortSubset(
#   #     cohortIds = uniqueSubsetCriteria$indicationId,
#   #     negate = FALSE,
#   #     cohortCombinationOperator = "all",
#   #     startWindow = CohortGenerator::createSubsetCohortWindow(-99999, 0, "cohortStart"),
#   #     endWindow = CohortGenerator::createSubsetCohortWindow(0, 99999, "cohortStart")
#   #   )
#   # }
#   subsetOperators[[length(subsetOperators) + 1]] <- CohortGenerator::createLimitSubset(
#     priorTime = 365,
#     followUpTime = 1,
#     limitTo = "firstEver"
#   )
#   if (uniqueSubsetCriteria$genderConceptIds != "" ||
#       uniqueSubsetCriteria$minAge != "" ||
#       uniqueSubsetCriteria$maxAge != "") {
#     subsetOperators[[length(subsetOperators) + 1]] <- CohortGenerator::createDemographicSubset(
#       ageMin = if(uniqueSubsetCriteria$minAge == "") 0 else as.integer(uniqueSubsetCriteria$minAge),
#       ageMax = if(uniqueSubsetCriteria$maxAge == "") 99999 else as.integer(uniqueSubsetCriteria$maxAge),
#       gender = if(uniqueSubsetCriteria$genderConceptIds == "") NULL else as.integer(strsplit(uniqueSubsetCriteria$genderConceptIds, ",")[[1]])
#     )
#   }
#   if (studyStartDate != "" || studyEndDate != "") {
#     subsetOperators[[length(subsetOperators) + 1]] <- CohortGenerator::createLimitSubset(
#       calendarStartDate = if (studyStartDate == "") NULL else as.Date(studyStartDate, "%Y%m%d"),
#       calendarEndDate = if (studyEndDate == "") NULL else as.Date(studyEndDate, "%Y%m%d")
#     )
#   }
#   subsetDef <- CohortGenerator::createCohortSubsetDefinition(
#     name = "",
#     definitionId = i,
#     subsetOperators = subsetOperators
#   )
#   cohortDefinitionSet <- cohortDefinitionSet %>%
#     CohortGenerator::addCohortSubsetDefinition(
#       cohortSubsetDefintion = subsetDef,
#       targetCohortIds = targetCohortIdsForSubsetCriteria
#     ) 
  
  # if (uniqueSubsetCriteria$indicationId != "") {
  #   # Also create restricted version of indication cohort:
  #   subsetDef <- CohortGenerator::createCohortSubsetDefinition(
  #     name = "",
  #     definitionId = i + 100,
  #     subsetOperators = subsetOperators[2:length(subsetOperators)]
  #   )
  #   cohortDefinitionSet <- cohortDefinitionSet %>%
  #     CohortGenerator::addCohortSubsetDefinition(
  #       cohortSubsetDefintion = subsetDef,
  #       targetCohortIds = as.integer(uniqueSubsetCriteria$indicationId)
  #     )
  # }  
# }

negativeControlOutcomeCohortSet <- CohortGenerator::readCsv(
  file = "inst/negativeControlOutcomes.csv"
)

if (any(duplicated(cohortDefinitionSet$cohortId, negativeControlOutcomeCohortSet$cohortId))) {
  stop("*** Error: duplicate cohort IDs found ***")
}

# CohortGeneratorModule --------------------------------------------------------
cgModuleSettingsCreator <- CohortGeneratorModule$new()
cohortDefinitionShared <- cgModuleSettingsCreator$createCohortSharedResourceSpecifications(cohortDefinitionSet)
negativeControlsShared <- cgModuleSettingsCreator$createNegativeControlOutcomeCohortSharedResourceSpecifications(
  negativeControlOutcomeCohortSet = negativeControlOutcomeCohortSet,
  occurrenceType = "first",
  detectOnDescendants = TRUE
)
cohortGeneratorModuleSpecifications <- cgModuleSettingsCreator$createModuleSpecifications(
  generateStats = TRUE
)

# CohortDiagnoticsModule Settings ---------------------------------------------
cdModuleSettingsCreator <- CohortDiagnosticsModule$new()
cohortDiagnosticsModuleSpecifications <- cdModuleSettingsCreator$createModuleSpecifications(
  cohortIds = cohortDefinitionSet$cohortId,
  runInclusionStatistics = TRUE,
  runIncludedSourceConcepts = TRUE,
  runOrphanConcepts = TRUE,
  runTimeSeries = FALSE,
  runVisitContext = TRUE,
  runBreakdownIndexEvents = TRUE,
  runIncidenceRate = TRUE,
  runCohortRelationship = TRUE,
  runTemporalCohortCharacterization = TRUE,
  minCharacterizationMean = 0.01
)

# CharacterizationModule Settings ---------------------------------------------
cModuleSettingsCreator <- CharacterizationModule$new()
allCohortIdsExceptOutcomes <- cohortDefinitionSet %>%
  filter(!cohortId %in% outcomes$cohortId) %>%
  pull(cohortId)

characterizationModuleSpecifications <- cModuleSettingsCreator$createModuleSpecifications(
  targetIds = allCohortIdsExceptOutcomes,
  outcomeIds = outcomes$cohortId, # original
  # outcomeIds = oList$outcomeCohortId, # Ruochong's edits
  outcomeWashoutDays = outcomes$cleanWindow,
  minPriorObservation = 365,
  dechallengeStopInterval = 30,
  dechallengeEvaluationWindow = 30,
  riskWindowStart = timeAtRisks$riskWindowStart, 
  startAnchor = timeAtRisks$startAnchor, 
  riskWindowEnd = timeAtRisks$riskWindowEnd, 
  endAnchor = timeAtRisks$endAnchor,
  minCharacterizationMean = .01
)


# CohortIncidenceModule --------------------------------------------------------
# ciModuleSettingsCreator <- CohortIncidenceModule$new()
# exposureIndicationIds <- cohortDefinitionSet %>%
#   filter(!cohortId %in% outcomes$cohortId & isSubset) %>%
#   pull(cohortId)
# targetList <- lapply(
#   exposureIndicationIds,
#   function(cohortId) {
#     CohortIncidence::createCohortRef(
#       id = cohortId, 
#       name = cohortDefinitionSet$cohortName[cohortDefinitionSet$cohortId == cohortId]
#     )
#   }
# )
# outcomeList <- lapply(
#   seq_len(nrow(outcomes)),
#   function(i) {
#     CohortIncidence::createOutcomeDef(
#       id = i, 
#       name = cohortDefinitionSet$cohortName[cohortDefinitionSet$cohortId == outcomes$cohortId[i]], 
#       cohortId = outcomes$cohortId[i], 
#       cleanWindow = outcomes$cleanWindow[i]
#     )
#   }
# )
# 
# tars <- list()
# for (i in seq_len(nrow(timeAtRisks))) {
#   tars[[i]] <- CohortIncidence::createTimeAtRiskDef(
#     id = i, 
#     startWith = gsub("cohort ", "", timeAtRisks$startAnchor[i]), 
#     endWith = gsub("cohort ", "", timeAtRisks$endAnchor[i]), 
#     startOffset = timeAtRisks$riskWindowStart[i],
#     endOffset = timeAtRisks$riskWindowEnd[i]
#   )
# }
# analysis1 <- CohortIncidence::createIncidenceAnalysis(
#   targets = exposureIndicationIds,
#   outcomes = seq_len(nrow(outcomes)),
#   tars = seq_along(tars)
# )
# # irStudyWindow <- CohortIncidence::createDateRange(
# #   startDate = studyStartDateWithHyphens,
# #   endDate = studyEndDateWithHyphens
# # )
# irDesign <- CohortIncidence::createIncidenceDesign(
#   targetDefs = targetList,
#   outcomeDefs = outcomeList,
#   tars = tars,
#   analysisList = list(analysis1),
#   #studyWindow = irStudyWindow,
#   strataSettings = CohortIncidence::createStrataSettings(
#     byYear = TRUE,
#     byGender = TRUE,
#     byAge = TRUE,
#     ageBreaks = seq(0, 110, by = 5)
#   )
# )
# cohortIncidenceModuleSpecifications <- ciModuleSettingsCreator$createModuleSpecifications(
#   irDesign = irDesign$toList()
# )


# CohortMethodModule -----------------------------------------------------------
cmModuleSettingsCreator <- CohortMethodModule$new()
covariateSettings <- FeatureExtraction::createDefaultCovariateSettings(
  addDescendantsToExclude = TRUE # Keep TRUE because you're excluding concepts
)
outcomeList <- append(
  lapply(seq_len(nrow(outcomes)), function(i) {
    if (useCleanWindowForPriorOutcomeLookback)
      priorOutcomeLookback <- outcomes$cleanWindow[i]
    else
      priorOutcomeLookback <- 99999
    CohortMethod::createOutcome(
      outcomeId = outcomes$cohortId[i],
      outcomeOfInterest = TRUE,
      trueEffectSize = NA,
      priorOutcomeLookback = priorOutcomeLookback
    )
  }),
  lapply(negativeControlOutcomeCohortSet$cohortId, function(i) {
    CohortMethod::createOutcome(
      outcomeId = i,
      outcomeOfInterest = FALSE,
      trueEffectSize = 1
    )
  })
)

#################### NEW, but wrong ############################################
# targetComparatorOutcomesList <- list()
# for (i in seq_along(tcis)) {
#   tci <- tcis[[i]]
#   # Get the subset definition ID that matches
#   # the target ID. The comparator will also use the same subset
#   # definition ID
#   currentSubsetDefinitionId <- dfUniqueTcis %>%
#     filter(cohortId == tci$targetId &
#              indicationId == paste(tci$indicationId, collapse = ",") &
#              genderConceptIds == paste(tci$genderConceptIds, collapse = ",") &
#              minAge == paste(tci$minAge, collapse = ",") &
#              maxAge == paste(tci$maxAge, collapse = ",")) %>%
#     pull(subsetDefinitionId)
#   targetId <- cohortDefinitionSet %>%
#     filter(subsetParent == tci$targetId & subsetDefinitionId == currentSubsetDefinitionId) %>%
#     pull(cohortId)
#   comparatorId <- cohortDefinitionSet %>% 
#     filter(subsetParent == tci$comparatorId & subsetDefinitionId == currentSubsetDefinitionId) %>%
#     pull(cohortId)
#   targetComparatorOutcomesList[[i]] <- CohortMethod::createTargetComparatorOutcomes(
#     targetId = targetId,
#     comparatorId = comparatorId,
#     outcomes = outcomeList,
#     excludedCovariateConceptIds = tci$excludedCovariateConceptIds
#   )
# }
################################################################################

############## Old / Typical: but should be correct ############################
targetComparatorOutcomesList <- list()
for (i in seq_len(nrow(cmTcList))) {
  targetComparatorOutcomesList[[i]] <- CohortMethod::createTargetComparatorOutcomes(
    targetId = cmTcList$targetCohortId[i],
    comparatorId = cmTcList$comparatorCohortId[i],
    outcomes = outcomeList,
    excludedCovariateConceptIds = c(
      cmTcList$targetConceptId[i], 
      cmTcList$comparatorConceptId[i],
      excludedCovariateConcepts$conceptId
    )
  )
}
################################################################################

getDbCohortMethodDataArgs <- CohortMethod::createGetDbCohortMethodDataArgs(
  restrictToCommonPeriod = TRUE,
  studyStartDate = studyStartDate,
  studyEndDate = studyEndDate,
  maxCohortSize = 0,
  covariateSettings = covariateSettings
)
createPsArgs = CohortMethod::createCreatePsArgs(
  maxCohortSizeForFitting = maxCohortSizeForFitting,
  errorOnHighCorrelation = TRUE,
  stopOnError = FALSE, # Setting to FALSE to allow Strategus complete all CM operations; when we cannot fit a model, the equipoise diagnostic should fail
  estimator = "att",
  prior = Cyclops::createPrior(
    priorType = "laplace", 
    exclude = c(0), 
    useCrossValidation = TRUE
  ),
  control = Cyclops::createControl(
    noiseLevel = "silent", 
    cvType = "auto", 
    seed = 1, 
    resetCoefficients = TRUE, 
    tolerance = 2e-07, 
    cvRepetitions = 1, 
    startingVariance = 0.01
  )
)
matchOnPsArgs = CohortMethod::createMatchOnPsArgs(
  maxRatio = psMatchMaxRatio,
  caliper = 0.2,
  caliperScale = "standardized logit",
  allowReverseMatch = FALSE,
  stratificationColumns = c()
)
# stratifyByPsArgs <- CohortMethod::createStratifyByPsArgs(
#   numberOfStrata = 5,
#   stratificationColumns = c(),
#   baseSelection = "all"
# )
computeSharedCovariateBalanceArgs = CohortMethod::createComputeCovariateBalanceArgs(
  maxCohortSize = maxCohortSize,
  covariateFilter = NULL
)
computeCovariateBalanceArgs = CohortMethod::createComputeCovariateBalanceArgs(
  maxCohortSize = maxCohortSize,
  covariateFilter = FeatureExtraction::getDefaultTable1Specifications()
)
fitOutcomeModelArgs = CohortMethod::createFitOutcomeModelArgs(
  modelType = "cox",
  stratified = psMatchMaxRatio != 1,
  useCovariates = FALSE,
  inversePtWeighting = FALSE,
  prior = Cyclops::createPrior(
    priorType = "laplace", 
    useCrossValidation = TRUE
  ),
  control = Cyclops::createControl(
    cvType = "auto", 
    seed = 1, 
    resetCoefficients = TRUE,
    startingVariance = 0.01, 
    tolerance = 2e-07, 
    cvRepetitions = 1, 
    noiseLevel = "quiet"
  )
)
cmAnalysisList <- list()
for (i in seq_len(nrow(timeAtRisks))) {
  createStudyPopArgs <- CohortMethod::createCreateStudyPopulationArgs(
    firstExposureOnly = FALSE,
    washoutPeriod = 0,
    removeDuplicateSubjects = "keep first",
    censorAtNewRiskWindow = TRUE,
    removeSubjectsWithPriorOutcome = TRUE,
    priorOutcomeLookback = 99999,
    riskWindowStart = timeAtRisks$riskWindowStart[[i]],
    startAnchor = timeAtRisks$startAnchor[[i]],
    riskWindowEnd = timeAtRisks$riskWindowEnd[[i]],
    endAnchor = timeAtRisks$endAnchor[[i]],
    minDaysAtRisk = 1,
    maxDaysAtRisk = 99999
  )
  cmAnalysisList[[i]] <- CohortMethod::createCmAnalysis(
    analysisId = i,
    description = sprintf(
      "Cohort method, %s",
      timeAtRisks$label[i]
    ),
    getDbCohortMethodDataArgs = getDbCohortMethodDataArgs,
    createStudyPopArgs = createStudyPopArgs,
    createPsArgs = createPsArgs,
    matchOnPsArgs = matchOnPsArgs,
    # stratifyByPsArgs = stratifyByPsArgs,
    computeSharedCovariateBalanceArgs = computeSharedCovariateBalanceArgs,
    computeCovariateBalanceArgs = computeCovariateBalanceArgs,
    fitOutcomeModelArgs = fitOutcomeModelArgs
  )
}
cohortMethodModuleSpecifications <- cmModuleSettingsCreator$createModuleSpecifications(
  cmAnalysisList = cmAnalysisList,
  targetComparatorOutcomesList = targetComparatorOutcomesList,
  analysesToExclude = NULL,
  refitPsForEveryOutcome = FALSE,
  refitPsForEveryStudyPopulation = FALSE,  
  cmDiagnosticThresholds = CohortMethod::createCmDiagnosticThresholds()
)


# SelfControlledCaseSeriesmodule -----------------------------------------------
# sccsModuleSettingsCreator <- SelfControlledCaseSeriesModule$new()
# uniqueTargetIds <- sccsTList$targetCohortId
# 
# eoList <- list()
# for (targetId in uniqueTargetIds) {
#   for (outcomeId in oList$outcomeCohortId) {
#     eoList[[length(eoList) + 1]] <- SelfControlledCaseSeries::createExposuresOutcome(
#       outcomeId = outcomeId,
#       exposures = list(
#         SelfControlledCaseSeries::createExposure(
#           exposureId = targetId,
#           trueEffectSize = NA
#         )
#       )
#     )
#   }
#   for (outcomeId in negativeControlOutcomeCohortSet$cohortId) {
#     eoList[[length(eoList) + 1]] <- SelfControlledCaseSeries::createExposuresOutcome(
#       outcomeId = outcomeId,
#       exposures = list(SelfControlledCaseSeries::createExposure(
#         exposureId = targetId, 
#         trueEffectSize = 1
#       ))
#     )
#   }
# }
# sccsAnalysisList <- list()
# analysisToInclude <- data.frame()
# for (i in seq_len(nrow(sccsIList))) {
#   # indicationId <- sccsIList$indicationCohortId[i] # original
#   indicationId <- sccsIList$targetCohortId[i] # Ruochong's edits
#   getDbSccsDataArgs <- SelfControlledCaseSeries::createGetDbSccsDataArgs(
#     maxCasesPerOutcome = 1000000,
#     useNestingCohort = TRUE,
#     nestingCohortId = indicationId,
#     studyStartDate = studyStartDate,
#     studyEndDate = studyEndDate,
#     deleteCovariatesSmallCount = 0
#   )
#   createStudyPopulationArgs = SelfControlledCaseSeries::createCreateStudyPopulationArgs(
#     firstOutcomeOnly = TRUE,
#     naivePeriod = 365,
#     minAge = 18,
#     genderConceptIds = c(8507, 8532)
#   )
#   covarPreExp <- SelfControlledCaseSeries::createEraCovariateSettings(
#     label = "Pre-exposure",
#     includeEraIds = "exposureId",
#     start = -30,
#     startAnchor = "era start",
#     end = -1,
#     endAnchor = "era start",
#     firstOccurrenceOnly = FALSE,
#     allowRegularization = FALSE,
#     profileLikelihood = FALSE,
#     exposureOfInterest = FALSE
#   )
#   calendarTimeSettings <- SelfControlledCaseSeries::createCalendarTimeCovariateSettings(
#     calendarTimeKnots = 5,
#     allowRegularization = TRUE,
#     computeConfidenceIntervals = FALSE
#   )
#   # seasonalitySettings <- SelfControlledCaseSeries:createSeasonalityCovariateSettings(
#   #   seasonKnots = 5,
#   #   allowRegularization = TRUE,
#   #   computeConfidenceIntervals = FALSE
#   # )
#   fitSccsModelArgs <- SelfControlledCaseSeries::createFitSccsModelArgs(
#     prior = Cyclops::createPrior("laplace", useCrossValidation = TRUE), 
#     control = Cyclops::createControl(
#       cvType = "auto", 
#       selectorType = "byPid", 
#       startingVariance = 0.1, 
#       seed = 1, 
#       resetCoefficients = TRUE, 
#       noiseLevel = "quiet")
#   )
#   for (j in seq_len(nrow(timeAtRisks))) {
#     covarExposureOfInt <- SelfControlledCaseSeries::createEraCovariateSettings(
#       label = "Main",
#       includeEraIds = "exposureId",
#       start = timeAtRisks$riskWindowStart[j],
#       startAnchor = gsub("cohort", "era", timeAtRisks$startAnchor[j]),
#       end = timeAtRisks$riskWindowEnd[j],
#       endAnchor = gsub("cohort", "era", timeAtRisks$endAnchor[j]),
#       firstOccurrenceOnly = FALSE,
#       allowRegularization = FALSE,
#       profileLikelihood = TRUE,
#       exposureOfInterest = TRUE
#     )
#     createSccsIntervalDataArgs <- SelfControlledCaseSeries::createCreateSccsIntervalDataArgs(
#       eraCovariateSettings = list(covarPreExp, covarExposureOfInt),
#       # seasonalityCovariateSettings = seasonalityCovariateSettings,
#       calendarTimeCovariateSettings = calendarTimeSettings
#     )
#     description <- "SCCS"
#     description <- sprintf("%s, having %s - male, female, age >= %s", description, cohortDefinitionSet %>% 
#                              filter(cohortId == indicationId) %>%
#                              pull(cohortName), createStudyPopulationArgs$minAge)
#     description <- sprintf("%s, %s", description, timeAtRisks$label[j])
#     sccsAnalysisList[[length(sccsAnalysisList) + 1]] <- SelfControlledCaseSeries::createSccsAnalysis(
#       analysisId = length(sccsAnalysisList) + 1,
#       description = description,
#       getDbSccsDataArgs = getDbSccsDataArgs,
#       createStudyPopulationArgs = createStudyPopulationArgs,
#       createIntervalDataArgs = createSccsIntervalDataArgs,
#       fitSccsModelArgs = fitSccsModelArgs
#     )
#   }
# }
# selfControlledModuleSpecifications <- sccsModuleSettingsCreator$createModuleSpecifications(
#   sccsAnalysisList = sccsAnalysisList,
#   exposuresOutcomeList = eoList,
#   combineDataFetchAcrossOutcomes = FALSE,
#   sccsDiagnosticThresholds = SelfControlledCaseSeries::createSccsDiagnosticThresholds(
#     mdrrThreshold = 10,
#     easeThreshold = 0.25,
#     timeTrendPThreshold = 0.05,
#     preExposurePThreshold = 0.05
#   )
# )

# Create the analysis specifications ------------------------------------------
analysisSpecifications <- Strategus::createEmptyAnalysisSpecificiations() |>
  Strategus::addSharedResources(cohortDefinitionShared) |> 
  Strategus::addSharedResources(negativeControlsShared) |>
  Strategus::addModuleSpecifications(cohortGeneratorModuleSpecifications) |>
  # Strategus::addModuleSpecifications(cohortDiagnosticsModuleSpecifications) |>
  Strategus::addModuleSpecifications(characterizationModuleSpecifications) |>
  # Strategus::addModuleSpecifications(cohortIncidenceModuleSpecifications) |>
  Strategus::addModuleSpecifications(cohortMethodModuleSpecifications)
  # Strategus::addModuleSpecifications(selfControlledModuleSpecifications)

ParallelLogger::saveSettingsToJson(
  analysisSpecifications,
  file.path("inst", "demoAnalysisSpecification_tcis.json")
)
