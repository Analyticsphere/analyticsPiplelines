library(bigrquery)
library(data.table)
library(boxr)
library(tidyverse)
library(dplyr)
library(reshape)  
library(stringr)
library(plyr)
library(bit64)
library(plumber)
library(lubridate)

# #* heartbeat...for testing purposes only. Not required to run analysis.
# #* @get /
# #* @post /
# function(){return("alive")}
# 
# #* Runs STAGE test script
# #* @get /test_api
# #* @post /test_api
# function() {
  
  # Authenticate BigQuery
  bq_auth()
  
  # Project and billing should be consistent
  project <- "nih-nci-dceg-connect-prod-6d04"
  billing <- "nih-nci-dceg-connect-prod-6d04" 
  
  # Query data and download table
  recr_query <- "SELECT * FROM 
                `nih-nci-dceg-connect-prod-6d04.recruitment.recruitment1_WL` 
                WHERE d_512820379 != '180583933'"
  recrbq <- bq_project_query(project=project, query=recr_query, billing=billing)
  recr_noinact_wl <- bq_table_download(recrbq, bigint="integer64")
  
  ##exclude PII variables:
  PII <- c("d_348474836","d_371067537","d_388711124","d_421823980","d_442166669","d_471168198","d_479278368","d_544150384","d_564964481",
           "d_635101039","d_736251808","d_765336427","d_793072415","d_795827569","d_826240317","d_849786503","d_869588347","d_892050548")
  
  
  ###convert the numeric
  data1 <- recr_noinact_wl
  cnames <- names(recr_noinact_wl)
  
  ###to check variables in recr_noinact_wl1
  for (i in 1: length(cnames)){
    varname <- cnames[i]
    var <- pull(data1,varname)
    data1[,cnames[i]] <- ifelse(numbers_only(var), as.numeric(as.character(var)), var)
  }
  
  recr_noinact_wl1 <- data1[,!(names(data1) %in% PII)]
  
  # Generate output file name
  currentDate <- Sys.Date()
  # output_fid <- paste(paste("prod_recrument1_WL_NM_noinactive_",
  #                           currentDate, ".csv", sep =""))
  # GENERATE TEST FILE
  file.create("testing_rec2box_pipeline.txt")
  output_fid <- "testing_rec2box_pipeline.txt"
  
  
  # Generate description 
  verified <- nrow(data1[which(recr_noinact_wl1$d_821247024==197316935),])
  box_description <- paste("Connect Prod flat Recruitment1_WL,",
                           currentDate, ":verified=", verified, sep="")
  
  # Authenticate and write to Box, BOX_CLIENT_ID & BOX_CLIENT_SECRET are stored 
  # as system variables. Problem: Must authenticate using interaction with browser.
  box_auth(client_id=Sys.getenv("BOX_CLIENT_ID"), 
           client_secret=Sys.getenv("BOX_CLIENT_SECRET"),
           interactive=FALSE, write.Renv=TRUE)
  box_setwd(dir_id = 161836233301) 
  box_write(object = recr_noinact_wl1,
            filename = output_fid,
            description = output_desc)
  
# }