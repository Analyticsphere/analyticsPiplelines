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

  # Change project and billing info as needed.
  project = "nih-nci-dceg-connect-stg-5519"  
  billing = "nih-nci-dceg-connect-stg-5519"
  
  # Designate bucket name (bucket must exist in GCP project) 
  bucket_name   <- 'test_analytics_bucket_jp' 
  report_folder <- 'report' 
  dir.create(report_folder)
  
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
  # Must include path to output folder in file name
  report_name <- 'report_table.pdf'
  #pdf_path    <- paste('./', report_folder, '/', report_name, sep = '') 
  pdf_path    <- './report/report_table.pdf' 
  pdf(pdf_path)              # Opens a PDF
  grid.table(t)              # Put table in PDF
  dev.off()                  # Closes PDF
  
  # Export output folder to bucket and to Box
  time_stamp  <- format(Sys.time(), "%m-%d-%Y-%H-%M-%S") # current date/time
  # Example box folder: https://nih.app.box.com/folder/175101221441
  box_folder  <- 175101221441 # number associated with box folder
#   bucket_path <- export_folder_contents_to_bucket(report_folder, bucket_name, 
#                                                   time_stamp)
#   box_path    <- export_folder_contents_to_box(report_folder, box_folder,
#                                                time_stamp)
  #token - token_fetch(app, scopes - c("https://www.googleapis.com/auth/cloud-platform"))
  #gcs_auth(token = token)
  #gcs_list _buckets(projectId = "nih-nci-dceg-druss")
  
  # Return a string for for API testing purposes
  ret_str <- paste("All done. Check", bucket_path, "for", report_name)
  print(ret_str)
  return(ret_str) 
}

