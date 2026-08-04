# checkReproducibilityOutput() checks that an output corresponds to a reference file saved as a .rds
  #!! Currently this does not work for "complex" figures generated with ggpubr/cowplot

  # Arguments:
  # -- obtained: the obtained output, can be any object (e.g. a data.frame, a tibble, a figure)
    # but must be saved as a .RDS object
    # does not work with PNG figures or CSV tables
  # -- ref_path: the expected values
  # -- ref_vis: an additional path that can be given for visual checks (e.g. figures but also csv tables)
  # -- print: set to TRUE to print elements of dissimilarity

checkReproducibilityOutput <- function(obtained, ref_path, ref_vis = NULL, print = F) {
  
    # Checking that file exists at reference path
  if(!file.exists(ref_path)) stop("No file was found at the specified path.")
  
    # Checking that file type is .rds
  file_type <- stringr::str_sub(ref_path, start = -4)
  if(file_type != ".rds") stop("The reference file should be saved as .rds")
  
    # Reading the reference type
  expected <- read_rds(ref_path)
  
    # Checking similarity with reference
  sim <- all.equal(obtained, expected)
  
  obtained_name <- deparse(substitute(obtained))

  if(isTRUE(sim)) message(paste(obtained_name, "corresponds to the expected output")) else {
    message(paste("Warning:", obtained_name, "does not correspond to the expected output"))
    message(paste("Check",  ref_path , "for expected output"))
    message("Or set `read_ref_output` to TRUE to read it.")
    if(print) {
      message("Elements of dissimilarity are displayed below")
      print(sim)
    } else {
      message("set 'print' argument to TRUE to print elements of dissimilarity")
    }

  }
  
}
