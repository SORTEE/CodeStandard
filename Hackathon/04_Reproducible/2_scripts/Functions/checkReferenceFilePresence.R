# checkReferenceFilePresence() verifies that all desired reference files for reproducibility checking
# are present in the right folder

checkReferenceFilePresence <- function(ref_path = "_results/ref") {
  
    # Name of outputs for which we want reference files for comparison
  outputs <- c("d_surv", "fig2", "fitness_loss_hatchedEarlier", "fitness_loss_hatchedLater",
               "glm_surv_anova", "glm_surv_res", "lm_weight_anova", "lm_weight_res",
               "p_relfit", "p_surv", "p_weight", "raw_surv", "raw_weight",
               "RelFit_means", "surv_avg", "weight")
  
  files <- paste0(outputs, "_expected.rds")
  
    # Checking presence in _results/ref folder
  file_presence <- sapply(paste(ref_path, files, sep = "/"), file.exists)
  
  if(sum(file_presence) == length(outputs)) 
    message(paste0("All reference files for reproducibility testing were found in ./", ref_path, ".")) else {
      message("Some reference files are missing for reproducibility testing.")
      message(paste("Missing outputs:", paste(outputs[file_presence == F], collapse = ", ")), ".")
    }
  
  message("To generate reference files again, set `save_ref_outputs` to TRUE\n(see next section), but be careful that these are the desired output versions!")
  
}