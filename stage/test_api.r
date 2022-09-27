# test_api.r
  
library(bigrquery)
library(gridExtra)

#* heartbeat...for testing purposes only. Not required to run analysis.
#* @get /
#* @post /
function(){return("alive")}

#* Runs STAGE test script
#* @get /test_api
function() {
  # Change project and billing info as needed.
  project = "nih-nci-dceg-connect-stg-5519"  
  billing = "nih-nci-dceg-connect-stg-5519"
  # Simple query.
  queryrec <- "SELECT 117249500 AS RcrtUP_Age_v1r0 
               FROM `nih-nci-dceg-connect-prod-6d04.Connect.participants` 
               WHERE Connect_ID IS NOT NULL"
  # BigQuery authorization. Should work smoothly on GCP without any inputs.
  bq_auth() 
  # Download some data
  rec_data <- bq_table_download(rec_table, bigint = "integer64")
  t <- head(rec_data) # Get just the top few lines of the table.
  # Write a table to pdf as an example "report".
  pdf('report_table.pdf')           # Opens a PDF
  grid.table(t)                     # Put table in PDF
  dev.off()                         # Closes PDF
}
  