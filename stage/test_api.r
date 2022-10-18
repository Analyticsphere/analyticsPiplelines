# test_api.r
#
# Written by: Jake Peters
# Date: October 2022
# Description: This R code is part of a test pipeline for the Connect Analytics
# team. It uses plumber to set up an API that can be called by Cloud Build/Run 
# on GCP. This code that requires cloud_run_helper_functions.r is in the working
# directory. 
  
library(bigrquery)
library(gridExtra)
library(plumber)
library(ggplot2)
library(gridExtra)
library(scales)
library(dplyr)
library(boxr)

source("cloud_run_helper_functions.r")

#* heartbeat...for testing purposes only. Not required to run analysis.
#* @get /
#* @post /
function(){return("alive")}

#* Runs STAGE test script
#* @get /test_api
#* @post /test_api
function() {

  # Set parameters 
  report_name <- 'report_table.pdf'
  bucket      <- 'gs://test_analytics_bucket_jp' 
  project     <- "nih-nci-dceg-connect-stg-5519"  
  billing     <- project # Billing must be same as project
  
  # Simple query.
  query_rec <- "SELECT 117249500 AS RcrtUP_Age_v1r0 
                FROM `nih-nci-dceg-connect-stg-5519.Connect.participants` 
                WHERE Connect_ID IS NOT NULL"
  
  # BigQuery authorization. Should work smoothly on GCP without any inputs.
  bq_auth() 
  
  # Download some data
  rec_table <- bq_project_query(project, query_rec)
  rec_data  <- bq_table_download(rec_table, bigint = "integer64")
  t <- head(rec_data) # Get just the top few lines of the table.
  
  # Write a table to pdf as an example "report". 
  # Add time stamp to report name
  report_fid <- paste0(file_path_sans_ext(report_name),
                       format(Sys.time(), "_%m_%d_%Y_%H_%M"),
                       ".", file_ext(report_name))
  pdf(report_fid) # Opens a PDF
  grid.table(t)   # Put table in PDF
  dev.off()       # Closes PDF
  
  # Authenticate with Google Storage and write report file to bucket
  scope <- c("https://www.googleapis.com/auth/cloud-platform")
  token <- token_fetch(scopes=scope)
  gcs_auth(token=token)
  gcs_upload(report_fid, bucket=bucket, name=report_fid) 
  
  # Return a string for for API testing purposes
  ret_str <- paste("All done. Check", bucket, "for", report_fid)
  print(ret_str)
  return(ret_str) 
}

