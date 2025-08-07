# To read a reference file for reproducibility checks

readReferenceFile <- function(obj_name, ref_path = "_results/ref") {
  
  file_name <- paste0(obj_name, "_expected.rds")
  file <- paste(ref_path, file_name, sep = "/")
  ref <- read_rds(file)
  return(ref)
  
}