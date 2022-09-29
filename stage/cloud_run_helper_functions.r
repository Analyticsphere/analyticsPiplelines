## Helper functions for cloud run

## Uses gsutil CLI command to copy files from directory to a GCP bucket.
export_folder_contents_to_bucket <- function(output_directory, bucket_path) {
  
  # Modify strings to so that gsutil will recognize them
  output_path_str <- paste(output_directory, '/', sep='')
  bucket_path_str <- paste('gs://', bucket_path, 
                           '/$(date +"%d-%m-%Y-%H-%M-%S")/', # Add timestamp
                           sep = '') 
  print(output_path_str)
  print(bucket_path_str)
  
  # Run gsutil command to to copy contents of output file to bucket
  res <- sys::exec_wait('gsutil', 'cp', '-R', output_directory, bucket_path)
}

# Checks if packages are available and logs to text file for debugging cloud runs
# and Docker setup. Takes package names as strings as inputs.
check_package_availability <- function(...){
  packages <- list(...)
  file.create("./output/package_availability.txt")
  for (package in packages){
    if (package %in% rownames(installed.packages()) == TRUE) {
      line_str <- paste(package, 'is available', sep =" ")
      write(line, file = "/output/package_availability.txt", append = TRUE)
    } else {
      line_str <- paste(package, 'is not available', sep =" ")
      write(line, file = "/output/package_availability.txt", append = TRUE)
    }
  }
}