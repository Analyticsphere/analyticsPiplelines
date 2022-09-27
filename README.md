# testPiplineCloudRun
This repo holds files requires to run a containerized R script, using docker, cloud build and cloud run. Based on Daniels CloudRun_QAQC example.

- **cloudbuild.yaml**
```
steps:
 # Build the container image
 - name: 'gcr.io/cloud-builders/docker'
   args: ['build','-t', 'gcr.io/nih-nci-dceg-connect-stg-5519/qaqc-api:$COMMIT_SHA', '.']
   dir: 'stage'
   timeout: 1200s
 # Push the container image to Container Registry
 - name: 'gcr.io/cloud-builders/docker'
   args: ['push', 'gcr.io/nih-nci-dceg-connect-stg-5519/qaqc-api:$COMMIT_SHA']
 # Deploy container image to Cloud Run
 - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
   entrypoint: gcloud
   args: ['run','deploy','qaqc-api',
          '--image=gcr.io/nih-nci-dceg-connect-stg-5519/qaqc-api:$COMMIT_SHA',
          '--region=us-central1',
          '--service-account=qa-qc-stage@nih-nci-dceg-connect-stg-5519.iam.gserviceaccount.com']
images:
 - 'gcr.io/nih-nci-dceg-connect-stg-5519/qaqc-api:$COMMIT_SHA'
```
- **dockerfile**
```
FROM rocker/tidyverse:latest
RUN install2.r rio plumber bigrquery
COPY ["./api.R", "./api.R"]
ENTRYPOINT ["R", "-e","pr <- plumber::plumb('api.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]
```
