#### Analysis of <PROJECT NAME> ####

# In this study, <brief description of study>.
# <Important study details>.
# <Experimental design>.


# To run this script: open the R project in the main folder of this repository.


## Setup ---------------------------------------------------------------------------------------
# This section loads the required packages, reads in the data required for the analysis, and
# provides some simple summaries of the data structure.


## Load R environment --------------------------------------------------------------------------
# NB: the user needs to have Rtools installed to be able to download package versions
#     that are only available as source files.

# Need to install packages?
install_needed <- TRUE

# Want to use renv to restore the versions of packages used in the original analysis?
use_renv <- TRUE

# Install packages and set up environment
if(install_needed) {
  
  if(use_renv) {
    
    renv::restore()
    # NB: this only works well when the R version used is the same as recorded 
    #     in the renv.lock file (here: v.4.5.2)
    # if renv::restore() fails, restart R, turn USE_RENV to FALSE and try again
  } else {
    # when renv::restore() fails, delete the renv.lock file
    file.remove("renv.lock")
    
    # and create and record your own environment
    renv::init()
    renv::snapshot()
  }
  
  # Install any packages that renv misses
  if(!require(<package1>)) renv::install("<package1>")
  if(!require(<package2>)) renv::install("<package2>")
  
}

# Check that analysis environment was set up well
renv::status()
# NB: resolve any issues following renv instructions

# Setting seed to ensure random processes are reproducible
set.seed(<seed>)


## Load packages -------------------------------------------------------------------------------

library(tidyverse)         # Used for data cleaning and manipulation (includes dplyr library)
library(performance)       # Used to check model assumptions
library(testthat)          # Used for unit tests
library(knitr)             # Used to automatically turn script into .Rmarkdown file
library(rmarkdown)         # Used to automatically turn .Rmd into HTML file
library(<package>)         # <describe use of package in this script>

...


## User configuration --------------------------------------------------------------------------

# set to TRUE to save figures
save_figures <- TRUE

# set to TRUE to save tables
save_tables <- TRUE

# create output directory if saving is enabled
if(save_figures | save_tables) {
  
  if(!dir.exists("output")) dir.create("output")
  if(!dir.exists("output/result")) dir.create("output/result")
  if(!dir.exists("output/fig")) dir.create("output/fig")
  
}


## Download data ------------------------------------------------------------------------------
# To run this script, the dataset '<filename>' needs to be downloaded from:
# <repository or DOI>
#
# The dataset should be saved in the folder data/

# Create folder to store the data
if(!dir.exists("data")) dir.create("data")

# Check if data is present in folder if not yet exists
file_name <- "<filename>"
file_path <- file.path("data", file_name)

# If not, want to automatically download it from the repository (does not require user input)?
download_data <- TRUE

if(download_data == TRUE & file.exists(file_path) == FALSE) {
  # Specify doi of the repository and download
  doi <- "<doi>"
  tmp_files <- rdryad::dryad_download(doi)[[doi]]
  # use deposits::deposit_download_file() for zenodo and figshare: https://github.com/ropenscilabs/deposits
  
  # Copy desired file to data folder
  file.copy(
    tmp_files[grepl(file_name, tmp_files)],
    "data",
    overwrite = TRUE
  )
  
}
# or manually place the data file in data/


## Load data -----------------------------------------------------------------------------------

data_raw <- read.csv(file_path)


## Data summary -------------------------------------------------------------------------------

# Quick checks of the data's structure
class(data_raw) # object type
head(data_raw) # print the first 6 rows
dim(data_raw) # number of rows and columns
str(data_raw) # check variable classes
summary(data_raw) # dataset summary

# Additional notes on variables
# ...

# Check for outliers
hist(data$<variable>)
hist(data$<variable>)

# Check sample sizes
test_that("Sample size", {expect_equal(length(unique(data$<variable>)), <expected_sample_size>})

# Expected sample size:
# Actual sample size:

# Check missing data
xtabs(~ <factor1> + <factor2>, data = data)

# Other applicable unit tests
test_that("<description>", {
  expect_equal(...)
})


## <Analysis section title> --------------------------------------------------------------------
# This section analyses <analysis objective>.
# The data is first prepared, then visualised.
# Statistical models are fitted and predictions plotted.


## Data preparation ---------------------------------------------------------------------------

analysis_data <- data %>%
  mutate(...) %>%
  select(...) %>%
  filter(...)

# Tests after data manipulation
test_that("<description>", {
  expect_equal(...)
})

# Check structure of cleaned data
head(analysis_data)
levels(analysis_data$factor)


## Visualize raw data --------------------------------------------------------------------------

# Aggregate the data in a meaningful way for visualization
summary_data <- aggregate(...)
head(summary_data)


## Raw data figure -----------------------------------------------------------------------------

raw_plot <- ggplot(...) +
  ...

# View figure
raw_plot

# Save to outputs
if(save_figures) {
  ggsave(filename = "output/fig/<figure_name>.png",
         plot = raw_plot,
         width = 200,
         height = 150,
         units = "mm",
         dpi = "print")
}


## Fit statistical model -----------------------------------------------------------------------

# <Describe chosen model>
model_step1 <- <model_function>(...)

# Check model assumptions
performance::check_model(model_step1)

# Use ANOVA to check significance of covariates
anova_step1 <- ...

# Label model
anova_step1$mod <- "<model_name>"

# Refit model dropping terms
model_step2 <- update(...)

# Test significance of updated model with ANOVA
anova_step2 <- ...

# Pick final model
model_final <- model_step2

# Check model assumptions
performance::check_model(model_final)

# View model summary 
summary(model_final)

# Extract estimated coefficients as dataframe
model_results <- summary(model_final)$coefficients %>% as.data.frame()

# Save model outputs
if(save_tables) {
  write.csv(model_results, file = "output/result/<model_results>.csv", row.names = TRUE)
}


## Predict -------------------------------------------------------------------------------------

# Create input data for prediction
prediction_data <- ...

# Predict variable of interest
prediction_data$pred <- predict(model_final, newdata = prediction_data, type = "<prediction type>")

# View first rows of dataset
head(prediction_data)


## Predicted vs observed figure ---------------------------------------------------------------------------

prediction_plot <- raw_plot +
  ...

# View plot
prediction_plot

# Save the figure
if(save_figures) {
  ggsave(filename = "output/fig/<prediction_figure>.png",
         plot = prediction_plot,  
         width = 200,
         height = 150,
         units = "mm",
         dpi = "print"
         )
}


# End of <analysis section> / script
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

## Quick and dirty: automatically turn script into Rmarkdown file but do not yet knit

knitr::spin("scripts/<analysis_script>.R", knit = FALSE)

# Converted .Rmd file to HTML in RStudio by:
# 1. Opening generated .Rmd file
# 2. Removing the final script lines
# 3. Knit -> Knit Directory -> Project directory
# 4. Knit -> Knit to HTML