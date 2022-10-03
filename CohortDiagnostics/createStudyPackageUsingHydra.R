remotes::install_github("OHDSI/Hydra")
outputFolder <- "d:/temp/output"  # location where you study package will be created

baseUrl <- "https://atlas.ohdsi.org/WebAPI"
ROhdsiWebApi::setAuthHeader(baseUrl = baseUrl, 
                            authHeader = "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJzY2h1ZW1pZXN5c3RlbUBnbWFpbC5jb20iLCJTZXNzaW9uLUlEIjpudWxsLCJleHAiOjE2NjQ4NjY5Mjl9.tmNp2_Y2kMZVXyjphgrPJfESmtOoKx6EH_3NaGf6QMBsBjPl4IsJZtnZcFIWgroRrOAStrlniC5zQcQLYl1hTg")

cohortDefinitionsMetadata <- ROhdsiWebApi::getCohortDefinitionsMetaData(baseUrl = baseUrl)
targetCohortIds <- cohortDefinitionsMetadata %>% 
  dplyr::filter(stringr::str_detect(string = .data$name, pattern = stringr::fixed("[OHDSI2022]"))) %>% 
  dplyr::filter(stringr::str_detect(string = .data$name, pattern = stringr::fixed("COPY OF"), negate = TRUE)) %>% 
  dplyr::pull(.data$id) %>% 
  unique()


########## Please populate the information below #####################
version <- "v0.1.0"
name <- "OHDSI Tutorial 2022 Cohort Diangostics"
packageName <- "ohdsiTutorial2022CohortDiagnostics"
skeletonVersion <- "v0.0.1"
createdBy <- "gowthamrao@gmail.com"
createdDate <- Sys.Date() # default
modifiedBy <- "gowthamrao@gmail.com"
modifiedDate <- Sys.Date()
skeletonType <- "CohortDiagnosticsStudy"
organizationName <- "OHDSI"
description <- "Cohort diagnostics on Cohorts for OHDSI Tutorial."



################# end of user input ##############
studyCohorts <-  cohortDefinitionsMetadata %>% 
        dplyr::filter(.data$id %in% targetCohortIds)

# compile them into a data table
cohortDefinitionsArray <- list()
for (i in (1:nrow(studyCohorts))) {
        cohortDefinition <-
                ROhdsiWebApi::getCohortDefinition(cohortId = studyCohorts$id[[i]],
                                                  baseUrl = baseUrl)
        cohortDefinitionsArray[[i]] <- list(
                id = studyCohorts$id[[i]],
                createdDate = studyCohorts$createdDate[[i]],
                modifiedDate = studyCohorts$createdDate[[i]],
                logicDescription = studyCohorts$description[[i]],
                name = stringr::str_trim(stringr::str_squish(cohortDefinition$name)),
                expression = cohortDefinition$expression
        )
}

tempFolder <- tempdir()
unlink(x = tempFolder, recursive = TRUE, force = TRUE)
dir.create(path = tempFolder, showWarnings = FALSE, recursive = TRUE)

specifications <- list(id = 1,
                       version = version,
                       name = name,
                       packageName = packageName,
                       skeletonVersion = skeletonVersion,
                       createdBy = createdBy,
                       createdDate = createdDate,
                       modifiedBy = modifiedBy,
                       modifiedDate = modifiedDate,
                       skeletonType = skeletonType,
                       organizationName = organizationName,
                       description = description,
                       cohortDefinitions = cohortDefinitionsArray)

jsonFileName <- paste0(file.path(tempFolder, "CohortDiagnosticsSpecs.json"))
write(x = specifications %>%  RJSONIO::toJSON(pretty = TRUE, digits = 23), file = jsonFileName)


##############################################################
##############################################################
#######       Get skeleton from github            ############
#######       Uncomment if you want to use latest ############
#######       skeleton only - for advanced user   ############
##############################################################
##############################################################
##############################################################
#### get the skeleton from github
download.file(url = "https://github.com/OHDSI/SkeletonCohortDiagnosticsStudy/archive/refs/heads/main.zip",
                         destfile = file.path(tempFolder, 'skeleton.zip'))
unzip(zipfile =  file.path(tempFolder, 'skeleton.zip'),
      overwrite = TRUE,
      exdir = file.path(tempFolder, "skeleton")
        )
fileList <- list.files(path = file.path(tempFolder, "skeleton"), full.names = TRUE, recursive = TRUE, all.files = TRUE)
DatabaseConnector::createZipFile(zipFile = file.path(tempFolder, 'skeleton.zip'),
                                 files = fileList,
                                 rootFolder = list.dirs(file.path(tempFolder, 'skeleton'), recursive = FALSE))

##############################################################
##############################################################
#######               Build package              #############
##############################################################
##############################################################
##############################################################


#### Code that uses the ExampleCohortDiagnosticsSpecs in Hydra to build package
hydraSpecificationFromFile <- Hydra::loadSpecifications(fileName = jsonFileName)
unlink(x = outputFolder, recursive = TRUE)
dir.create(path = outputFolder, showWarnings = FALSE, recursive = TRUE)

# for advanced user using skeletons outside of Hydra
Hydra::hydrate(specifications = hydraSpecificationFromFile,
               outputFolder = outputFolder,
               skeletonFileName = file.path(tempFolder, 'skeleton.zip')
)


unlink(x = tempFolder, recursive = TRUE, force = TRUE)


##############################################################
##############################################################
######       Build, install and execute package           #############
##############################################################
##############################################################
##############################################################
