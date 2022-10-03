library(magrittr)

################################################################################
# VARIABLES - please change
################################################################################
# The folder where the study intermediate and result files will be written:
outputFolder <- "D:/studyResults/ohdsiTutorial2022CohortDiagnostics"
# create output directory if it does not exist
if (!dir.exists(outputFolder)) {
  dir.create(outputFolder,
             showWarnings = FALSE,
             recursive = TRUE)
}
# Optional: specify a location on your disk drive that has sufficient space.
options(andromedaTempFolder = file.path(outputFolder, "andromedaTemp"))

# lets get meta information for each of these databaseId. This includes connection information.
source("extras/examples/dataSourceInformation.R")

############## databaseIds to run cohort diagnostics on that source  #################
databaseIds <- 'iqvia_pharmetrics_plus'

## service name for keyring for db with cdm
keyringUserService <- 'OHDSI_USER'
keyringPasswordService <- 'OHDSI_PASSWORD'

cdmSource <- cdmSources %>%
  dplyr::filter(.data$sequence == 1) %>%
  dplyr::filter(database == databaseIds)

outputFolder <- file.path(outputFolder, cdmSource$sourceKey)

cdmSource$serverFinal <- cdmSource$server
cdmSource$cohortDatabaseSchemaFinal <-
  cdmSource$cohortDatabaseSchema
cdmSource$cdmDatabaseSchemaFinal <- cdmSource$cdmDatabaseSchema
cdmSource$runOn <- "OHDA"
cdmSource$vocabDatabaseSchemaFinal <- cdmSource$vocabDatabaseSchema

cohortTableName <- paste0("ohdsi2022_", cdmSource$sourceId)

extraLog <- (
  paste0(
    "Running ",
    cdmSource$sourceName,
    " on ",
    cdmSource$runOn,
    "\n     server: ",
    cdmSource$runOn,
    " (",
    cdmSource$serverFinal,
    ")",
    "\n     cdmDatabaseSchema: ",
    cdmSource$cdmDatabaseSchemaFinal,
    "\n     cohortDatabaseSchema: ",
    cdmSource$cohortDatabaseSchemaFinal
  )
)

# Details for connecting to the server:
connectionDetails <-
  DatabaseConnector::createConnectionDetails(
    dbms = cdmSource$dbms,
    server = cdmSource$serverFinal,
    user = keyring::key_get(service = "OHDSI_USER"),
    password =  keyring::key_get(service = "OHDSI_PASSWORD"),
    port = cdmSource$port
  )
# The name of the database schema where the CDM data can be found:
cdmDatabaseSchema <- cdmSource$cdmDatabaseSchemaFinal
vocabDatabaseSchema <- cdmSource$vocabDatabaseSchemaFinal
cohortDatabaseSchema <- cdmSource$cohortDatabaseSchemaFinal

databaseId <- cdmSource$sourceKey
databaseName <- cdmSource$sourceName
databaseDescription <- cdmSource$sourceName

ohdsiTutorial2022CohortDiagnostics::execute(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTable = cohortTableName,
  verifyDependencies = FALSE,
  outputFolder = outputFolder,
  databaseId = databaseId,
  databaseName = databaseName,
  databaseDescription = databaseDescription,
  extraLog = extraLog
)

CohortDiagnostics::createMergedResultsFile(dataFolder = outputFolder, overwrite = TRUE)
