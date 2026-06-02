# checkOutputPresence() verifies if outputs were already generated and stored in the right folder

checkOutputPresence <- function(path = "_results") {
  
    # Name of outputs for which we want reference files for comparison
  outputs <- c("anova_PupaWeight_lmer.csv", 
               "anova_Surv_glmer.csv",
               "figure_2.png",
               "FitnessCurve_rev.png",
               "output_PupaWeight_lmer.csv",
               "output_Surv_glmer.csv",
               "PupWeight_raw.png",
               "PupWeight_wpred_rev.png",
               "Survival_raw.png",
               "Survival_wpred_rev.png")

    # Checking presence in _results/ref folder
  file_presence <- sapply(paste(path, outputs, sep = "/"), file.exists)
  
  if(sum(file_presence) == length(outputs)) 
    message(paste0("All desired outputs were already generated and stored in ./", path, ".")) else {
      message("Not all desired outputs were already generated.")
      message(paste("Missing outputs:", paste(outputs[file_presence == F], collapse = ", ")), ".")
    }
  
  message("To generate outputs again, set `save_figures` and /or `save_tables` to TRUE\n(see next section).")
  
}
