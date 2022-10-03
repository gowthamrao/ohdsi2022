# where are the cohort diagnostics output?
folderWithZipFilesToUpload <-
  "D:\\studyResults\\ohdsiTutorial2022CohortDiagnostics\\"
remotes::install_github("gowthamrao/CohortDiagnostics", ref = "execute2")

library(magrittr)
# what is the name of the schema you want to upload to?
resultsSchema <- 'ohdsi2022Tut' # change to your schema

# sqlCreate <-
#   paste0("SELECT CREATE_SCHEMA('@results_database_schema');")
# DatabaseConnector::renderTranslateExecuteSql(
#   connection = DatabaseConnector::connect(connectionDetails = connectionDetails),
#   sql = sqlCreate,
#   results_database_schema = resultsSchema
# )

# Postgres server: connection details to OHDSI Phenotype library. Please change to your postgres connection details
connectionDetails <- DatabaseConnector::createConnectionDetails(
  dbms = Sys.getenv("shinydbDbms", unset = "postgresql"),
  server = paste(
    Sys.getenv("phenotypeLibraryServer"),
    Sys.getenv("phenotypeLibrarydb"),
    sep = "/"
  ),
  port = Sys.getenv("phenotypeLibraryDbPort"),
  user = Sys.getenv("phenotypeLibrarydbUser"),
  password = Sys.getenv("phenotypeLibrarydbPw")
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

sqlGrant <-
  "grant select on all tables in schema @results_database_schema to phenotypelibrary;"
DatabaseConnector::renderTranslateExecuteSql(
  connection = DatabaseConnector::connect(connectionDetails = connectionDetails),
  sql = sqlGrant,
  results_database_schema = resultsSchema
)

sqlGrantTable <- "GRANT ALL ON  @results_database_schema.annotation TO  phenotypelibrary;
                   GRANT ALL ON  @results_database_schema.annotation_link TO  phenotypelibrary;
                   GRANT ALL ON  @results_database_schema.annotation_attributes TO  phenotypelibrary;"

DatabaseConnector::renderTranslateExecuteSql(
  connection = DatabaseConnector::connect(connectionDetails = connectionDetails),
  sql = sqlGrantTable,
  results_database_schema = resultsSchema
)
