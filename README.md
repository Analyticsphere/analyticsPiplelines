# Example R Analytics Pipeline:

## using Plumber, Cloud Build, Cloud Run and Cloud Scheduler

This repo holds files requires to run a containerized R script, using docker, cloud build and cloud run. It uses docker and yaml files based on Daniel Russ's CloudRun_QAQC example.

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
library(plumber)
library(gridExtra)

#* heartbeat...for testing purposes only. Not required to run analysis.
#* @get /
#* @post /
function(){return("alive")}

#* Runs STAGE test script
#* @get /qaqc
function() {
  
  # Change project and billing info as needed.
  project = "nih-nci-dceg-connect-stg-5519"  
  billing= "nih-nci-dceg-connect-stg-5519"
  
  # Simple query.
  queryrec <- "SELECT 117249500 AS RcrtUP_Age_v1r0 
  FROM `nih-nci-dceg-connect-prod-6d04.Connect.participants` where Connect_ID IS NOT NULL"
  
  # BigQuery authorization. Should work smoothly on GCP without any inputs.
  bq_auth() 
  
  # Download some data
  rec_data <- bq_table_download(rec_table, bigint = "integer64")
  test_report_table <- head(rec_data) # Get just the top few lines of the table.
  
  # Write a table to pdf as an example "report".
  pdf('report_table.pdf')
  grid.table(test_report_table)
  dev.off()
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
     - 'gcr.io/nih-nci-dceg-connect-stg-5519/qaqc-api:$COMMIT_SHA'

-   **Dockerfile** is a text file that contains all of commands that are needed to run your code, including installing software. This is used to create a docker image, or a lightweight software package that has all the dependencies required to run an application on any platform, including GCP Cloud Run. These commands are written in order.
    -   *`rocker/tidyverse`* is a collection of commonly used R data science packages

    -   *`install2.r`* is a command that takes R packages as inputs. Add any R packages needed to run your R code to this list if they are not in the latest version of tidyverse. If they are in tidyverse, don't add them because it will add to the build time. You can look up tidyverse packages [here](https://tidyverse.tidyverse.org/reference/tidyverse_packages.html).

    -   *`COPY` ...* copies your R file and puts it in a new directory. Be sure to change the name of this file to that of your R code.

    -   *`ENTRYPOINT ["R",`* ... calls a plumber method using R. Be sure to change \<your_api.r\> to the name of your R file. Run R code. Code must use plumber API commands and be inside of a function.

    -   *`RUN gsutil cp` ...* Copies all of the files in the "output" folder of the instance to folder in a Google Storage Bucket named *test_analytics_bucket_jp*. The directory in the bucket is given a unique time stamp. For more information about running `gcloud` and `gsutil` commands within Cloud Run, look [here](https://cloud.google.com/run/docs/tutorials/gcloud). For more information about setting up a Google Storage Bucket, look [here](https://cloud.google.com/storage/docs/discover-object-storage-console). *test_analytics_bucket_jp* is a bucket that I made for this example.

<!-- -->

    # Dockerfile

    # Install packages
    FROM rocker/tidyverse:latest
    RUN install2.r plumber bigrquery gridExtra

    # Copy R code to directory in instance
    COPY ["./test_api.R", "./test_api.R"]

    # Run R code
    ENTRYPOINT ["R", "-e","pr <- plumber::plumb('test_api.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]

    # Copy output folder to gcp bucket **THIS NEEDS TO BE TESTED, NOT SURE IF IT SHOULD BE HERE.
    RUN gsutil cp --recursive output/ gs://test_analytics_bucket_jp/$(date +"%d-%m-%Y-%H-%M-%S")/

### 3. Schedule or Trigger the Cloud Run

-   ToDo

    -   Notes:

        -   Workflows:

            -   <https://cloud.google.com/workflows/docs/controlling-execution-order>

        -   Scheduler:

            -   <https://cloud.google.com/run/docs/execute/jobs-on-schedule#console>

            -   <https://cloud.google.com/run/docs/triggering/using-scheduler>

        -   Trigger with GitHub:

            -   

        -   Trigger with Table Event:

            -   <https://cloud.google.com/blog/topics/developers-practitioners/how-trigger-cloud-run-actions-bigquery-events>

### 4. Push data from GCP Cloud Storage Bucket to Box

-   ToDo

-   Notes:

    -   Can move data from Google Drive to Box: <https://support.box.com/hc/en-us/articles/7900885766163-Migrating-content-from-Google-Drive-to-Box>

### Notes:

It is also possible to do all of this using R libraries.

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
