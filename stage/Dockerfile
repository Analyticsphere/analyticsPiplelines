# Dockerfile

FROM rocker/tidyverse:latest
RUN install2.r plumber bigrquery gridExtra scales boxr

# Copy R code to directory in instance
COPY ["./test_api.r", "./test_api.r"]
COPY ["./cloud_run_helper_functions.r", "./cloud_run_helper_functions.r"]

# Make output folder for R script to put data into
#RUN mkdir -p /output 

# Run R code
ENTRYPOINT ["R", "-e","pr <- plumber::plumb('test_api.r'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]

# Copy output folder to gcp bucket **THIS NEEDS TO BE TESTED, NOT SURE IF IT SHOULD BE HERE.
# RUN gsutil cp -R output/ gs://test_analytics_bucket_jp/$(date +"%d-%m-%Y-%H-%M-%S")/
