# Dockerfile

FROM rocker/tidyverse:latest
RUN install2.r plumber gridExtra scales boxr bigrquery dplyr gmodels epiDisplay lubridate tidyverse gt kableExtra knitr gtsummary tidyr tinytex

# Copy R code to directory in instance
COPY ["./ccc_module_metrics_api.R", "./ccc_module_metrics_api.R"]
COPY ["./ccc_module_metrics.rmd", "./cloud_run_helper_functions.r"]

# Run R code
ENTRYPOINT ["R", "-e","pr <- plumber::plumb('ccc_module_metrics_api.R'); pr$run(host='0.0.0.0', port=as.numeric(Sys.getenv('PORT')))"]

