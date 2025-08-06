# checkReproducibilityValues() checks that a given numerical output corresponds to the expected set of values

  # Arguments:
  # -- obtained: an object containing one or several numerical/integer values 
    # (e.g. number of individuals)
    # (can be different classes)
  # -- expected: the expected values

checkReproducibilityValues <- function(obtained, expected) {
  
  obtained_vect <- as.vector(obtained) # to get rid of element names
  obtained_name <- deparse(substitute(obtained)) # to get object name
  
  cat("Expected value(s): ")
  cat(expected)
  
  if(all.equal(obtained_vect, expected) == TRUE)
    message(paste(obtained_name, "correspond to the expected value(s)")) else {
      message(paste("Warning:", obtained_name, "do not correspond to the expected value(s)"))
      message(paste("Obtained value(s):", paste(obtained_vect, collapse = "", sep = " ")))
    }
      
  
}


