# Dockerfile

FROM rocker/tidyverse:latest
RUN install2.r plumber bigrquery gridExtra scales boxr tools googleCloudStorageR gargle

# Copy R code to directory in instance
COPY ["./test_api.r", "./test_api.r"]
COPY ["./cloud_run_helper_functions.r", "./cloud_run_helper_functions.r"]

# Run R code
ENTRYPOINT ["R", "-e","pr <- plumber::plumb('test_api.r'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]