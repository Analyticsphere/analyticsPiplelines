# Dockerfile

FROM rocker/tidyverse:latest
RUN install2.r rio plumber bigrquery

# Copy R code to directory in instance
COPY ["./api.R", "./api.R"]

# Make output folder for R script to put data into
RUN mkdir -p /output 

# Run R code
ENTRYPOINT ["R", "-e","pr <- plumber::plumb('api.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]

# Copy output folder to gcp bucket **THIS NEEDS TO BE TESTED, NOT SURE IF IT SHOULD BE HERE.
# RUN gsutil cp -R output/ gs://test_analytics_bucket_jp/$(date +"%d-%m-%Y-%H-%M-%S")/
