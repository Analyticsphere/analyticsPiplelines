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


# Export data to Box
export_folder_contents_to_box<- function(output_folder, box_folder,
                                         time_stamp) {
  
  # Check if boxr is installed
  if (!require(boxr)) {         
    stop("boxr not installed")  
  } else {  
    print('boxr is installed')  
    
    # Authenticate Box user using client id and client secret
    # These are stored in .Renviron file. Get these from Jake or Daniel.
    # In Cloud Build/Run/Scheduler, these can be added as environment variables 
    # in the UI.
    box_auth(client_id=Sys.getenv("BOX_CLIENT_ID"), 
             client_secret=Sys.getenv("BOX_CLIENT_SECRET"),
             interactive=FALSE, write.Renv=TRUE)
    
    # Go to desired directory and create new folder
    box_setwd(box_folder)
    box_dir_name = paste('report', time_stamp, sep = '_')
    box_dir_create(dir_name, parent_dir_id = box_getwd())
    
    # Loop through files in output_folder and write them to box
    files <- list.files(path=output_folder, full.names=TRUE, recursive=FALSE)
    for (file in files){
      f <- load(file)
      box_write(f, file)
    }
  }
  
  return(box_dir_name)
}