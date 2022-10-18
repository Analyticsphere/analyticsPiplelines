# Example R Analytics Pipeline:

using Plumber, Cloud Build, Cloud Run and Cloud Scheduler

This repo holds files required to run a containerized R script, using docker, cloud build and cloud run. It uses docker and yaml files based on Daniel Russ's CloudRun_QAQC example.

### **Objectives:**

1.  Write R script as a plumber API

2.  Build a container image

3.  Schedule or trigger the cloud run

4.  Push data from GCP Cloud Storage Bucket to Box

### 1. Write R script as a plumber API

-   **test_api.r** is a R file containing your plumber API and R function. Below is an example:

```{r}
# test_api.r
  
library(bigrquery)
library(gridExtra)
library(plumber)
library(ggplot2)
library(gridExtra)
library(scales)
library(dplyr)
library(boxr)

source("cloud_run_helper_functions.r") # required

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
  bucket_path <- export_folder_contents_to_bucket(report_folder, bucket_name, 
                                                  time_stamp)
  box_path    <- export_folder_contents_to_box(report_folder, box_folder,
                                               time_stamp)
  
  # Return a string for for API testing purposes
  ret_str <- paste("All done. Check", bucket_path, "for", report_name)
  print(ret_str)
  return(ret_str) 
}
```

-   **cloud_run_helper_functions.r** contains helper functions used in test_api.r.
    -   `export_folder_contents_to_bucket` uses `gsutil` to copy files from a local directory to GCP bucket.

        -   input: `output_directory` is the directory holding the reporting output files to be copied

        -   input: `bucket_path` is the path to the bucket where you would like to put the files

        -   input: `time_stamp` to be added to new report folder name

    -   `check_package_availability` takes a list of R packages as inputs and checks whether they are available. Outputs to *output/package_availability.txt.* This is useful for debugging during a Cloud Run.

    -   `export_folder_contents_to_box` uses `boxr` to copy files from a local directory to GCP bucket.

        -   input: `output_directory` is the directory holding the reporting output files to be copied

        -   input: `box_folder` is the path to the bucket where you would like to put the files

        -   input: `time_stamp` to be added to new report folder name

```{r}
# cloud_run_helper_functions.r

# Helper functions for cloud run

## Uses gsutil CLI command to copy files from directory to a GCP bucket.
export_folder_contents_to_bucket <- function(output_directory, 
                                             bucket_path, 
                                             time_stamp) {
  
  # Modify strings to so that gsutil will recognize them
  output_path_str <- paste(output_directory, '/', sep='')
  bucket_path_str <- paste('gs://', bucket_path, '/report_', time_stamp, '/', 
                           sep = '') 
  
  # Run gsutil command to to copy contents of output file to bucket
  command = paste('gsutil', 'cp', '-R', 
                  output_path_str, bucket_path_str, sep =' ')
  system(command, intern=TRUE)
  
  return(bucket_path_str)
}

# Checks if packages are available and logs to text file for debugging cloud runs
# and Docker setup. Takes package names as strings as inputs.
check_package_availability <- function(...){
  packages <- list(...)
  file.create("./output/package_availability.txt")
  for (package in packages){
    if (package %in% rownames(installed.packages()) == TRUE) {
      line_str <- paste(package, 'is available', sep =" ")
      write(line_str, file = "./output/package_availability.txt", append = TRUE)
    } else {
      line_str <- paste(package, 'is not available', sep =" ")
      write(line_str, file = "./output/package_availability.txt", append = TRUE)
    }
  }
}

# Export data to Box
export_folder_contents_to_box<- function(output_folder, box_folder,
                                         time_stamp) {
  
  # Check if boxr is installed
  if (!require(boxr)) {         
    stop("boxr not installed")  
  } else {  
    print('boxr is installed')  
    
    # Authenticate user
    print(Sys.getenv("BOX_CLIENT_ID"))
    box_auth(client_id=Sys.getenv("BOX_CLIENT_ID"), 
             client_secret=Sys.getenv("BOX_CLIENT_SECRET"),
             interactive=FALSE, write.Renv=TRUE)
    
    # Go to desired directory and create new folder
    box_setwd(box_folder)
    box_dir_name = paste('report_', time_stamp, sep = '')
    box_dir_create(dir_name, parent_dir_id = box_getwd())
    
    # Loop through files in output_folder and write them to box
    files <- list.files(path=output_folder, full.names=TRUE, recursive=FALSE)
    for (file in files){
      f <- load(file)
      box_write(f, file)
    }
  }
}
```

### 2. Build a container image

Building a container image requires 2 files. A cloud build config file (ex, *cloudbuild.yaml*) and a docker file (ex, *Dockerfile*).

-   **cloudbuild.yaml** is a build config file that lists instructions for Cloud Build to build a container image, push the container image to a Container Registry on GCP, and deploy the container image to cloud run. For more information on build config files, see this [GCP reference page](https://cloud.google.com/build/docs/build-config-file-schema).

    -   Replace `nih-nci-dceg-connect-stg-5519` with your gcp project id

    -   Replace `test-api` with the api that you have configured on gcp,

    -   Replace `qa-qc-stage@nih-nci-dceg-connect-stg-5519.iam.gserviceaccount.com` with the name of your service account

<!-- -->

    # cloudbuild.yaml

    steps:

     # Build the container image
     - name: 'gcr.io/cloud-builders/docker'
       args: ['build','-t', 'gcr.io/nih-nci-dceg-connect-stg-5519/test-api:$COMMIT_SHA', '.']
       dir: 'stage'
       timeout: 1200s
       
     # Push the container image to Container Registry
     - name: 'gcr.io/cloud-builders/docker'
       args: ['push', 'gcr.io/nih-nci-dceg-connect-stg-5519/test-api:$COMMIT_SHA']
       
     # Deploy container image to Cloud Run
     - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
       entrypoint: gcloud
       args: ['run','deploy','qaqc-api',
              '--image=gcr.io/nih-nci-dceg-connect-stg-5519/test-api:$COMMIT_SHA',
              '--region=us-central1',
              '--service-account=qa-qc-stage@nih-nci-dceg-connect-stg-5519.iam.gserviceaccount.com']
              
    images:
     - 'gcr.io/nih-nci-dceg-connect-stg-5519/test-api:$COMMIT_SHA'

-   **Dockerfile** is a text file that contains all of commands that are needed to run your code, including installing software. This is used to create a docker image, or a lightweight software package that has all the dependencies required to run an application on any platform, including GCP Cloud Run. These commands are written in order.
    -   *`rocker/tidyverse`* is a collection of commonly used R data science packages

    -   *`install2.r`* is a command that takes R packages as inputs. Add any R packages needed to run your R code to this list if they are not in the latest version of tidyverse. If they are in tidyverse, don't add them because it will add to the build time. You can look up tidyverse packages [here](https://tidyverse.tidyverse.org/reference/tidyverse_packages.html).

    -   *`COPY` ...* copies your R file and puts it in a new directory. Be sure to change the name of this file to that of your R code.

    -   *`ENTRYPOINT ["R",`* ... calls a plumber method using R. Be sure to change \<your_api.r\> to the name of your R file. Run R code. Code must use plumber API commands and be inside of a function.

<!-- -->

    # Dockerfile

    FROM rocker/tidyverse:latest
    RUN install2.r plumber bigrquery gridExtra scales boxr

    # Copy R code to directory in instance
    COPY ["./test_api.r", "./test_api.r"]
    COPY ["./cloud_run_helper_functions.r", "./cloud_run_helper_functions.r"]

    # Run R code
    ENTRYPOINT ["R", "-e","pr <- plumber::plumb('test_api.r'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]

### 3. Schedule or Trigger the Cloud Run

-   ***ToDo***

    -   Notes:

        -   Scheduler:

            -   <https://cloud.google.com/run/docs/execute/jobs-on-schedule#console>

            -   <https://cloud.google.com/run/docs/triggering/using-scheduler>

        -   Trigger with Table Event:

            -   <https://cloud.google.com/blog/topics/developers-practitioners/how-trigger-cloud-run-actions-bigquery-events>

### 4. Push data from GCP Cloud Storage Bucket to Box

-   ***ToDo***

-   Notes:

    -   R package for interacting with Box:
        -   <https://cran.r-project.org/web/packages/boxr/vignettes/boxr.html>

        -   Tutorial: <https://ijlyttle.github.io/boxr/articles/boxr.html#authorizing-from-a-remote-server>

        -   Creating a folder with CLI: <https://developer.box.com/guides/cli/quick-start/build-commands-help/>

### Notes:

It is also possible to do all of this using R libraries. Daniel and Jake don't recommend it.

-   Tutorials:

    -   [Automate R script in the Cloud](https://medium.com/@damiencaillet/automate-r-code-in-the-cloud-89266910cc36){style="color: blue; font-style: italic"} by Damien Caillet

    -   [An ELT from scratch with googleCloudRunner, Docker, GCP and R](https://www.davidsolito.com/post/2021-05-30-an-elt-from-scratch-with-googlecloudrunner-docker-google-cloud-platform-and-r/) by R package build

    -   [Run R Code on a Schedule](https://code.markedmondson.me/googleCloudRunner/articles/usecase-scheduled-r-builds.html) by Mark Edmonson

    -   [Generating Dockerfiles for reproducible research with R](https://o2r.info/2017/05/30/containerit-package/) by Daniel Nust, Mathias Hinz

-   YouTube:

    -   [Complete Set Up Guide for googleCloudRunner - configuring the GCP console and your R environment](https://youtu.be/RrYrMsoIXsw) by Mark Edmondson

    -   [Schedule an RMarkdown (Rmd) file and host in the Google Cloud - googleCloudRunner](https://youtu.be/BainmerWVb0) by Mark Edmondson

-   Useful Links:

    -   <https://code.markedmondson.me/googleCloudRunner/>
