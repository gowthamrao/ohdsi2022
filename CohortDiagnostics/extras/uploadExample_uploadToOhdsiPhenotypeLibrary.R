# where are the cohort diagnostics output?
folderWithZipFilesToUpload <-
  "D:\\studyResults\\ohdsiTutorial2022CohortDiagnostics\\"
remotes::install_github("gowthamrao/CohortDiagnostics", ref = "execute2")

library(magrittr)
# what is the name of the schema you want to upload to?
resultsSchema <- 'ohdsi2022Tut' # change to your schema

# Postgres server: connection details to OHDSI Phenotype library. Please change to your postgres connection details
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = Sys.getenv("shinydbDbms", unset = "postgresql"),
  server = paste(
    Sys.getenv("shinydbServer"),
    Sys.getenv("shinydbDatabase"),
    sep = "/"
  ),
  port = Sys.getenv("shinydbPort"),
  user = Sys.getenv("shinydbUser"),
  password = Sys.getenv("shinydbPW")
)


# reading the tables in cohort diagnostics results data model
tablesInResultsDataModel <-
  CohortDiagnostics::getResultsDataModelSpecifications() %>%
  dplyr::select(.data$tableName) %>%
  dplyr::distinct() %>%
  dplyr::arrange() %>%
  dplyr::pull()

connection <-
  DatabaseConnector::connect(connectionDetails = connectionDetails)
for (i in (1:length(tablesInResultsDataModel))) {
  writeLines(paste0("Dropping table ", tablesInResultsDataModel[[i]]))
  DatabaseConnector::renderTranslateExecuteSql(
    connection = connection,
    sql = "DROP TABLE IF EXISTS @database_schema.@table_name CASCADE;",
    database_schema = resultsSchema,
    table_name = tablesInResultsDataModel[[i]]
  )
  
}

CohortDiagnostics::createResultsDataModel(connectionDetails = connectionDetails, schema = resultsSchema)

Sys.setenv("POSTGRES_PATH" = Sys.getenv('POSTGRES_PATH'))

listOfZipFilesToUpload <-
  list.files(
    path = folderWithZipFilesToUpload,
    pattern = ".zip",
    full.names = TRUE,
    recursive = TRUE
  )


for (i in (1:length(listOfZipFilesToUpload))) {
  CohortDiagnostics::uploadResults(
    connectionDetails = connectionDetails,
    schema = resultsSchema,
    zipFileName = listOfZipFilesToUpload[[i]]
  )
}


# Maintenance
connection <-
  DatabaseConnector::connect(connectionDetails = connectionDetails)
for (i in (1:length(tablesInResultsDataModel))) {
  # vacuum
  DatabaseConnector::renderTranslateExecuteSql(
    connection = connection,
    sql = "VACUUM VERBOSE ANALYZE @database_schema.@table_name;",
    database_schema = resultsSchema,
    table_name = tablesInResultsDataModel[[i]]
  )
}
