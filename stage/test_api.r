# test_api.r
  
library(bigrquery)
library(gridExtra)
library(plumber)
library(ggplot2)
library(gridExtra)
library(scales)
library(dplyr)
library(boxr)


dir.create("output")

source("cloud_run_helper_functions.r")

# Report package availability to text file for debugging purposes
check_package_availability("bigrquery", "gridExtra", "plumber", "ggplot2", 
                           "gridExtra", "scales", "dplyr")

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
  output_folder <- 'output' # Do not change this! Must correspond to Dockerfile.
  
  # Simple query.
  query_rec <- "SELECT 117249500 AS RcrtUP_Age_v1r0 
               FROM `nih-nci-dceg-connect-prod-6d04.Connect.participants` 
               WHERE Connect_ID IS NOT NULL"
  
  # BigQuery authorization. Should work smoothly on GCP without any inputs.
  bq_auth() 
  
  # Download some data
  rec_table <- bq_project_query(project, query_rec)
  rec_data <- bq_table_download(rec_table, bigint = "integer64")
  t <- head(rec_data) # Get just the top few lines of the table.
  
  # Write a table to pdf as an example "report". 
  # Must include path to output folder in file name
  report_name = './output/report_table.pdf'
  pdf(report_name)           # Opens a PDF
  grid.table(t)              # Put table in PDF
  dev.off()                  # Closes PDF
  
  # Export output folder to bucket
  export_folder_contents_to_bucket(output_folder, bucket_name)
  
  return("All done.")
}

