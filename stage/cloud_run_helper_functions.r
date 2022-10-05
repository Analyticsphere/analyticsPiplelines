# cloud_run_helper_functions.r

# Helper functions for cloud run

## Uses gsutil CLI command to copy files from directory to a GCP bucket.
export_folder_contents_to_bucket <- function(output_directory, bucket_path) {
  
  # Modify strings to so that gsutil will recognize them
  output_path_str <- paste(output_directory, '/', sep='')
  time_stamp      <- timestamp
  bucket_path_str <- paste('gs://', bucket_path, 
                           '/$(date +"%d-%m-%Y-%H-%M-%S")/', # Add timestamp
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

#TODO Complete write_to_box function including authentification
write_to_box <- function(id, secret) {
  if (!require(boxr)) {
    stop("boxr not installed")
  } else {
    print('boxr is installed')
    # box_auth(client_id = id, client_secret = secret)
    # box_setwd(175101221441)
    #https://nih.app.box.com/folder/175101221441
  }
}