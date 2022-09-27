library(bigrquery)
library(googleCloudStorageR)
library(ggplot2)
library(gridExtra)
library(scales)
library(dplyr)

#* heartbeat...
#* @get /
#* @post /
function(){
  return("alive")
}

#* Runs STAGE qa_qc
#* @get /qaqc
#* @post /qaqc
function() {

  project = "nih-nci-dceg-connect-prod-6d04"
  billing= "nih-nci-dceg-connect-prod-6d04"
  querymod <- "SELECT * FROM `nih-nci-dceg-connect-prod-6d04.flat.module1_scheduledqueries` where Connect_ID IS NOT NULL"
  queryrec <- "SELECT  Connect_ID, token, d_512820379, d_471593703, state.d_934298480, d_230663853,
  d_335767902, d_982402227, d_919254129, d_699625233, d_564964481, d_795827569, d_544150384,
  d_371067537, d_430551721, d_821247024, d_914594314,  state.d_725929722,
  d_949302066 , d_517311251, d_205553981
  FROM `nih-nci-dceg-connect-prod-6d04.Connect.participants` where Connect_ID IS NOT NULL"
  
  bq_auth()
  
  mod1_table <- bq_project_query(project, querymod)
  rec_table <- bq_project_query(project, queryrec)
  
  mod1_data <- bq_table_download(mod1_table, bigint = "integer64")
  rec_data <- bq_table_download(rec_table, bigint = "integer64")
  
  merged=merge(mod1_data, rec_data, by.x="Connect_ID", by.y="Connect_ID", all.x=T)
  dim(merged)
  
  merged <- merged %>% filter(d_512820379==486306141 | d_512820379==854703046)
  dim(merged)
  
  active <- merged %>% filter(d_512820379==486306141)
  dim(active)
  passive <- merged %>% filter(d_512820379==854703046)
  dim(passive)
  
  # Write a table to pdf
  pdf('report_table.pdf')
  grid.table(passive[1:5, 1:5])
  dev.off()
  
  # Write the table to a bucket
  project2 = "nih-nci-dceg-connect-dev"
  billing2 = "nih-nci-dceg-connect-dev"
  
  ################### START ###############################
  
  options(googleAuthR.scopes.selected = "https://www.googleapis.com/auth/cloud-platform")
  # load the libraries
  library("googleAuthR")
  gar_gce_auth()
  
  
  name <- c("john","doe")
  id <- c(1,2)
  results = as.data.frame(cbind(name,id))
  print("writing results to GCS")
  
  # Set bucket name
  bucket <- "test_analytics_team_bucket"
  gcs_global_bucket(bucket)
  print("bucket set.")
  
  
  # Upload that file to the global bucket
  gcs_upload(file = results , name = "results.csv")
  
  ################## END ################################
  gcs_list_buckets(project2)

}