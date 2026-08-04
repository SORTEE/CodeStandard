#### Analysis of <PROJECT NAME> ####

## In this study, <brief description of study>.
## <Important study details>.
## <Experimental design>.

################################################################################
### GUIDELINES FOR RECORDING AND REPRODUCING THE ANALYSIS ENVIRONMENT
###
### We recommend using R package renv.
###
### Recommended workflow to record your R environment:
###   renv::init()
###   renv::snapshot()
###
### Recommended workflow to restore your R environment:
###   renv::restore()
###
### This restores package versions recorded in a renv.lock file and helps
### reproduce the original analysis environment.
################################################################################


################################################################################
### GUIDELINES FOR COMMENTING YOUR SCRIPTS
###
### Comments should explain:
###
### - Why an operation is performed
### - How it relates to the manuscript
### - Important assumptions
### - Data processing decisions
###
### Avoid comments that merely repeat the code.
###
### Good:
### "Convert temperature to Kelvin because the model requires
### absolute temperature"
###
### Poor:
### "Add 273.15 to temperature"
################################################################################



## Setup -----------------------------------------------------------------------

## This section loads the required packages, reads in the data required for the
## analysis, and provides some simple summaries of the data structure.

library(<package>) # <describe purpose of package in this script>
library(<package>) # <describe purpose of package in this script>


## User configuration ----------------------------------------------------------

## set to TRUE to save figures
save_figures <- TRUE

## set to TRUE to save tables
save_tables <- TRUE

## create output directory if saving is enabled
if(save_figures | save_tables) {
  
  if(!dir.exists("output")) dir.create("output")
  if(!dir.exists("output/result")) dir.create("output/result")
  if(!dir.exists("output/fig")) dir.create("output/fig")
  
}


## Load data -------------------------------------------------------------------
data <- <add your code to read in the data>


## Data preparation -----------------------------------------------------------

## Purpose:
##
## <Describe how the raw data are transformed into the final dataset
## used for the analysis.>

analysis_data <- data %>%
  mutate(...) %>%
  select(...) %>%
  filter(...)

## Reproducibility checks

### Examples:
### - expected sample size
### - expected number of sites
### - expected number of taxa
### - expected factor levels
### - absence of duplicated observations
### - successful data joins

test_that("<description of expected property>", {
  expect_equal(...)
})

## Check structure of processed dataset

head(analysis_data)
str(analysis_data)
summary(analysis_data)

## <Add additional notes relevant for interpretation>
##
## ...


## Summary statistics ------------------------------------

## <Describe the purpose of the summary statistics.>
##
## i.e. These analyses should help understand the data structure and
## identify potential issues but should not replace formal analyses.

summary_data <- ...

head(summary_data)


## Exploratory figure ---------------------------------------------------------

exploratory_plot <- ggplot(...) +
  ...

## View figure

exploratory_plot

## Save figure

if(save_figures) {
  
  ggsave(
    filename = "output/fig/<figure_name>.png",
    plot = exploratory_plot,
    width = 200,
    height = 150,
    units = "mm",
    dpi = "print"
  )
  
}


## Primary analysis -----------------------------------------------------------

## Analysis objective:
##
## Response variable(s):
## Explanatory variable(s):
## Assumptions:
##
## Relation to manuscript:
## Figure/Table:
##
## <Explain WHY this analysis is performed.>

analysis_result <- <analysis_function>(...)

## Diagnostics and validation

### Examples:
### - model assumptions
### - convergence checks
### - simulation diagnostics
### - sensitivity analyses
### - cross-validation
### - posterior predictive checks

<diagnostic_code>
  
## View results
  
summary(analysis_result)

## Extract results into a table

analysis_results <- ...

## Save numerical output

if(save_tables) {
  
  write.csv(
    analysis_results,
    file = "output/result/<analysis_results>.csv",
    row.names = TRUE
  )
  
}


## Derived outputs ------------------------------------------------------------

### Optional section
###
### Examples:
### - predictions
### - estimated effects
### - ordination scores
### - diversity metrics
### - simulations
### - summary statistics
### - scenario projections
###
### Remove this section if not applicable.

derived_output <- ...

head(derived_output)


## Final figure or output -----------------------------------------------------

final_plot <- ggplot(...) +
  ...

final_plot

if(save_figures) {
  
  ggsave(
    filename = "output/fig/<final_figure>.png",
    plot = final_plot,
    width = 200,
    height = 150,
    units = "mm",
    dpi = "print"
  )
  
}

## End of analysis

### +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
