#### Analysis of Phenological mismatch experiment 2021 ####

# In this study, winter moth eggs were obtained from wild mothers caught in 2020. Timing of egg hatching
# was manipulated, with eggs either hatching on the day of budburst (Day0), before (Day-4 to -1),
# or after (Day+1 to +5). The photoperiod was also manipulated, with either a constant or changing
# photoperiod.


# To run this script: open the R project in the main folder of this repository.


## Setup ---------------------------------------------------------------------------------------
# This section loads the required packages, reads in the data required for the analysis, and
# provides some simple summaries of the data structure.


## Load R environment --------------------------------------------------------------------------
# NB: the user needs to have Rtools installed to be able to download the package versions 
#     that are only available as source files  

# Want to use renv to restore the versions of packages used in the original analysis?
USE_RENV <- FALSE # TRUE = Yes, FALSE = No 

if(USE_RENV) { 
  renv::restore()
  # NB: this only works well when the R version used is the same as recorded 
  #     in the renv.lock file (here: v.4.5.2)
  # if renv::restore() fails, restart R, turn USE_RENV to FALSE and try again
} else {
  # when renv::restore() fails, delete the renv.lock file
  file.remove("renv.lock")
  
  # and create and record your own environment
  renv::init()
}

# If error when downloading digest :
  # (this happens, check https://stackoverflow.com/questions/48548767/can-not-download-digest-package-in-r)
if(!require(digest)) {
  install.packages('digest', repos = 'http://cran.us.r-project.org')
}

# Check that installation of packages worked
renv::status()
# NB: resolve any issues by following renv advice

# Setting seed for random processes
set.seed(147)


## Load packages -------------------------------------------------------------------------------

library(rdryad)            # Used to download the data
library(tidyverse)         # Used for data cleaning and manipulation (includes dplyr library)
library(Rmisc)             # Used for calculating standard error and confidence intervals for data summaries
library(cowplot)           # Used for creating and arranging plots, providing a clean theme for publication
theme_set(theme_cowplot()) # Use white background instead of grey
library(lme4)              # Used for fitting linear and generalized linear mixed-effects models (LMMs and GLMMs)
library(lmerTest)          # Provides p-values for LMMs and GLMMs using Satterthwaite's approximation
library(performance)       # Used to check model assumptions
library(testthat)          # Used for unit tests
library(ggpubr)            # Used to arrange multiple figures


## User configuration ----------------------------------------------------------------------------

# set to TRUE to save figures (as .png files)
save_figures <- TRUE
# set to TRUE to save tables (as .csv files)
save_tables <- TRUE

# create output directory if saving is enabled and directories do not yet exist
if (save_figures | save_tables) {
  if(!dir.exists("output")) dir.create("output")
  if(!dir.exists("output/result")) dir.create("output/result")
  if(!dir.exists("output/fig")) dir.create("output/fig")
}


## Download data from dryad repository ----------------------------------------------------------

# To run this script, the dataset 'CatFood2021_deposit.csv' needs to be downloaded
  # from Dryad repository: 
  # https://doi.org/10.5061/dryad.m905qfv5p
  #
  # The dataset should be saved in the folder data/

# Create folders to store data
if(!dir.exists("data")) dir.create("data")

# Check if data is present in folder if not yet exists
file_name <- "CatFood2021_deposit.csv"
file_path <- file.path("data", file_name)

# If not, automatically download it from Dryad (does not require user input)
if(file.exists(file_path) == F) {
  # Download dryad repo in rdryad cache
  doi <- "10.5061/dryad.m905qfv5p"
  tmp_files <- rdryad::dryad_download(doi)[[doi]]

  # Copy desired file to data folder
  file.copy(tmp_files[grepl(file_name, tmp_files)], 
          "data", 
          overwrite = TRUE)
}
# or download the data file yourself (see link above) and place it in the data/ folder


## Load data -----------------------------------------------------------------------------------
# Data must be downloaded from the Dryad repository prior to running (see above)
cat_data_raw <- read.csv("data/CatFood2021_deposit.csv")


## Data summary -------------------------------------------------------------------------------

# Quick checks of the data's structure
class(cat_data_raw) # object type
head(cat_data_raw) # print the first 6 rows and the 19 columns
dim(cat_data_raw) # number of rows and columns
str(cat_data_raw) # check variable classes summary(cat_data_raw)

# renaming TubeID as MotherID to match the terminology used in the Statistical section of the paper
cat_data <- cat_data_raw %>% rename(MotherID = TubeID)

# The `Tree` column in this dataset refers to the tree ID where the mother moth 
# was caught as per the long-term field data collection described in the paper.

# Check for outliers
# Histograms should not show any outliers
hist(cat_data_raw$NovemberDate)
hist(cat_data_raw$PupaWeight_ingrams)
hist(cat_data_raw$DeadAprilDay)
hist(cat_data_raw$PupationAprilDay)
hist(cat_data_raw$PupaWeight_ingrams)
hist(cat_data_raw$AdultNovDate)
hist(cat_data_raw$AdultWeight_ingrams)

# Check sample size
test_that("22 different mothers", {expect_equal(length(unique(cat_data$MotherID)), 22)})
test_that("15 treatment values", {expect_equal(length(unique(cat_data$Treatment)), 15)})
table(cat_data$Treatment) # photoperiod and mismatch treatment coded in one variable

# Expected n = 22 clutches x 15 treatments x 3 replicates = 990
nrow(cat_data)
# Actual n = 976 -> missing 14 individuals

# Check missing data
xtabs(~ Treatment + MotherID, data = cat_data)
# specific clutch x treatment combinations with < 3 individuals:
# e.g., ConstDay0 x MotherID=16612 has 0; several others have 2 instead of 3
# some individuals lacked survival or weight data

nr_pupated <- sum(is.na(cat_data_raw$DeadAprilDay)) # number of caterpillars that pupated
nr_died <- sum(is.na(cat_data_raw$PupationAprilDay)) # number of caterpillars that died before pupation
nr_pup_died <- sum(is.na(cat_data_raw$AdultNovDate)) # number of pupae that died before adult emergence

# Check that number of missing data is consistent across columns
test_that("Died before pupation", {
  expect_equal(sum(is.na(cat_data_raw$PupationAprilDay)), sum(is.na(cat_data_raw$PupaWeight_ingrams)))
})

test_that("Died before adulthood", {
  expect_equal(sum(is.na(cat_data_raw$AdultNovDate)), sum(is.na(cat_data_raw$AdultWeight_ingrams)))
  expect_equal(sum(is.na(cat_data_raw$AdultWeight_ingrams)), sum(is.na(cat_data_raw$Sex)))
})

# N per Area
table(cat_data[!duplicated(cat_data$MotherID), "AreaShortName"])
# should match the counts given in section 2.b Phenological mismatch experiment


## <Survival analysis> ----------------------------------------------------------------------------
# This section analyses the consequences of day-to-day timing (a)synchrony with budburst on the 
# survival of caterpillars. The data is first prepared, then the raw survival data is plotted. 
# Generalised linear mixed models (GLMMs) are then fit to model the influence of treatment on survival, 
# and the predicted survival based on these models is plotted.


## Survival data preparation ------------------------------------------------------------------

# Reshape and clean the data to prepare it for analysis
cat_data_surv <- cat_data %>% 
  # Split treatment into its components (photoperiod and mismatch day):
  mutate(PhotoTreat = gsub("(\\w+)Day.+", "\\1", Treatment), 
         MismTreat = gsub("\\w+(Day.+)", "\\1", Treatment)) %>% 
  # Keep only relevant columns:
  select(MotherID, Treatment, PhotoTreat, MismTreat, 
         CaterpillarID, DeadAprilDay, PupationAprilDay) %>% 
  # Move the death and pupation dates into long format
  # This is necessary to create a "survival" variable that indicates whether the caterpillar died or survived to pupation:
  pivot_longer(cols = c(DeadAprilDay, PupationAprilDay),
               names_to = "Info", values_to = "TimeOfEvent") %>%
  # Remove missing values:
  filter(!is.na(TimeOfEvent)) %>%
  # Create the `survival` variable as a binary indicator for the binomial mixed model
  # Coded as 1 for death (`DeadAprilDay`) and 0 for survival (`PupationAprilDay`):
  mutate(survival = ifelse(Info == "DeadAprilDay", 1, 0)) %>% 
  # Convert variables into factors for modelling: 
  mutate(Treatment = as.factor(Treatment), 
         PhotoTreat = as.factor(ifelse(PhotoTreat == "Chang", "Changing", "Constant")), 
         MismTreatf = as.factor(MismTreat), 
         MotherID = as.factor(MotherID)) %>%
  # Order factor levels for treatments and get numeric version of mismatch day:      
  mutate(Treatment_releveled = factor(Treatment, levels = c("ChangDay-4", "ChangDay-3", "ChangDay-2",
                                                         "ChangDay-1", "ChangDay0", "ChangDay+1", 
                                                         "ChangDay+2", "ChangDay+3", "ChangDay+4",
                                                         "ChangDay+5",  "ConstDay-4", "ConstDay-2", 
                                                         "ConstDay0", "ConstDay+2", "ConstDay+4")), 
         MismTreat_factor = factor(MismTreat, levels = c("Day-4", "Day-3", "Day-2", "Day-1", "Day0", 
                                                     "Day+1", "Day+2", "Day+3", "Day+4", "Day+5")),
         MismTreat = as.numeric(gsub("Day(.+)", "\\1", MismTreat))) %>%
  # Transform mismatch treatment so that lowest value is 1, to be able to fit the squared term. 
  # And add a column with a quadratic term:
  mutate(MismTreat_noNeg = MismTreat - min(MismTreat) + 1, 
         MismTreat_squared = (MismTreat - min(MismTreat) + 1)^2) 


# Tests after data manipulation
test_that("Survival data table has correct class and dimensions", {
  expect_s3_class(cat_data_surv, "data.frame")
  expect_equal(ncol(cat_data_surv), 12)
  expect_equal(nrow(cat_data_surv), 976)
})
test_that("Treatment_releveled reflects Treatment", {
  expect_true(all(cat_data_surv$Treatment_releveled == cat_data_surv$Treatment))
  })
test_that("MismTreat_squared equals MismTreat_noNeg squared", {
  expect_true(all(cat_data_surv$MismTreat_squared == cat_data_surv$MismTreat_noNeg^2))
  })
test_that("Caterpillar ID are unique", {
  expect_equal(length(unique(cat_data_surv$CaterpillarID)), nrow(cat_data_surv))
  })

# Check structure of cleaned data
head(cat_data_surv) 

levels(cat_data_surv$Treatment_releveled)
levels(cat_data_surv$PhotoTreat)
levels(cat_data_surv$MismTreat_factor) 
levels(cat_data_surv$MotherID)

# 'TimeOfEvent' is date of either death or pupation
table(cat_data_surv$TimeOfEvent)

# 'survival' is the response variable (i.e., whether the caterpillar died or not) 
table(cat_data_surv$survival) 


## Visualize raw survival data --------------------------------------------------------------------------

# Get the number of deaths in each brood
surv_probs <- aggregate(survival ~ MismTreat + PhotoTreat + MotherID, cat_data_surv, sum)

# Add the number of individuals in each brood
surv_probs$samplesize <- aggregate(Info ~ MismTreat + PhotoTreat + MotherID, cat_data_surv, length)$Info

# Calculate the proportion of caterpillars surviving
surv_probs$probs <- 100 - (surv_probs$survival / surv_probs$samplesize * 100) 

# View first few rows
head(surv_probs)

# Take the average survival rate for each mismatch day (averaged over photoperiod treatments)
surv_avg <- Rmisc::summarySE(surv_probs, measurevar = "probs", groupvars = c("MismTreat")) 

# Add sample size
surv_avg$samplesize <- aggregate(Info ~ MismTreat, cat_data_surv, length)$Info

# View survival rates for each mismatch day
surv_avg


## Raw survival by mismatch day figure ----------------------------------------------------------------------------

raw_surv <- ggplot(data = surv_avg, aes(x = MismTreat, y = probs)) +
  scale_colour_manual(values = c("grey27", "orangered2")) +
  # Add transparent points for the survival rates split by photoperiod:
  geom_jitter(data = surv_probs, aes(col = PhotoTreat), alpha = 0.3, size = 3, height = 0.5, width = 0.25) +
  # Add points, errorbars, and labels for the mean survival by date:
  geom_point(size = 5, col = "black") +
  geom_errorbar(aes(ymax = probs+se, ymin = probs-se), width = 0.3, col = "black") +
  # Add labels for sample size:
  geom_text(aes(label = samplesize, y = probs+8.3), col = "black", size = 4, fontface = "bold") +
  labs(y = "Survival (%)", x = "Mismatch with oak budburst date (days)") +
  scale_y_continuous(breaks = seq(0, 100, by = 10)) + scale_x_continuous(breaks = seq(-4, 5, by = 1)) +
  theme(axis.title.y = element_text(size = 18, vjust = 2), axis.title.x = element_text(size = 18, vjust = -0.5),
        axis.text = element_text(size = 16), legend.text = element_text(size = 16), legend.title = element_text(size = 17))

# View figure
raw_surv 

# Save to outputs
if(save_figures) {
  ggsave(filename = "output/fig/Survival_raw.png",
         plot = raw_surv , device = "png",
         width = 200, height = 150, 
         units = "mm", dpi = "print")
}
  

## Fit binomial mixed survival model -----------------------------------------------------------------

# Fit generalised linear mixed model for probability of death, with a random effect for brood,
# fixed effects for mismatch treatment, mismatched treatment squared, and photoperiod, and
# interactions between mismatch and photoperiod treatments.
glmSurv_step1 <- lme4::glmer(survival ~ (MismTreat_noNeg + MismTreat_squared)*PhotoTreat + (1 | MotherID), 
                             family = binomial, 
                             data = cat_data_surv,
                             na.action = "na.fail",
                             control = glmerControl(calc.derivs = F)) # helps convergence
# Check model assumptions
performance::check_model(glmSurv_step1)

# Use ANOVA to check significance of covariates (here: interactions not significant)
anovaSurv_step1 <- drop1(glmSurv_step1,test = "Chi") %>% as.data.frame() 

# Label model
anovaSurv_step1$mod <- "glmSurv_step1"

# Refit without non-significant interactions
glmSurv_step2 <- update(glmSurv_step1, ~ . -MismTreat_noNeg:PhotoTreat - MismTreat_squared:PhotoTreat) 

# Test significance of updated model with ANOVA 
# (here: Photoperiod not significant, but both mismatch treatment fixed effects are)
anovaSurv_step2 <- drop1(glmSurv_step2,test = "Chi") %>% as.data.frame()
anovaSurv_step2$mod <- "glmSurv_step2"

# Use the model without interactions as the final model
glmSurv_final <- glmSurv_step2

# Check model assumptions
performance::check_model(glmSurv_final)

# # View model summary (NB: estimates are log odds)
summary(glmSurv_final)

# Extract estimated coefficients as dataframe
glmSurv_res <- summary(glmSurv_final)$coefficients %>% as.data.frame()

# Save model outputs
if(save_tables) {
  write.csv(glmSurv_res, file = "output/result/output_Surv_glmer.csv", row.names = T)
  write.csv(rbind(anovaSurv_step1, anovaSurv_step2), file = "output/result/anova_Surv_glmer.csv", row.names = T)
}


## Predict survival ---------------------------------------------------------------------------

# Remove duplicate replicates (same brood will have the same predicted values)
glmSurv_pred <- cat_data_surv[!duplicated(cat_data_surv[, c("MotherID", "Treatment_releveled")]),] 

# Predict the probability of death
glmSurv_pred$pred <- predict(glmSurv_final, newdata = glmSurv_pred, type = "response") 

# Invert to survival probability
glmSurv_pred$survprob <- (1 - glmSurv_pred$pred)

# View predicted survival probability by day (here: peaks at Day 2)
SurvByMismTreat <- aggregate(survprob ~ MismTreat, data = glmSurv_pred, mean)

# Calculate survival probability relative to peak
MismTreat_SurvPeak <- SurvByMismTreat$MismTreat[SurvByMismTreat$survprob == max(SurvByMismTreat$survprob)] 
glmSurv_pred$rel <- glmSurv_pred$survprob / mean(filter(glmSurv_pred, MismTreat == MismTreat_SurvPeak)$survprob) 

# View first rows of dataset
head(glmSurv_pred)


## Predicted survival figure ------------------------------------------------------------------

# Get predicted daily survival averaged across the two photoperiod treatments
pred_surv <- Rmisc::summarySE(glmSurv_pred, measurevar = "survprob", groupvars = c("MismTreat")) 
pred_surv$samplesize <- aggregate(CaterpillarID ~ MismTreat, data = cat_data_surv, length)$CaterpillarID

# Add predictions to raw survival figure
p_surv <- raw_surv +
  geom_smooth(data = pred_surv, aes(y = survprob*100), se = FALSE, colour = "red3")

# View plot
p_surv

# Save the figure
if(save_figures) {
  ggsave(filename = "output/fig/Survival_wpred_rev.png",
         plot = p_surv, device = "png", 
         width = 200, height = 150,
         units = "mm", dpi = "print"
         )
  
}
  
# End of survival analysis
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


## <Pupation weight analysis> ------------------------------------------------------------------
# This section analyses the impact of mismatch day and photoperiod on weight at pupation. 
# Data is prepared, raw data are plotted, and then GLMMs are fit to identify the influence of
# treatment on weight at pupation, and the predicted pupation weights based on these models 
# are plotted.


## Pupation data preparation ------------------------------------------------------------------

# Reshape and clean the data to prepare it for analysis
cat_data_pupa <- cat_data %>%
  # Split treatment into its components (photoperiod and mismatch day):
  mutate(PhotoTreat = gsub("(\\w+)Day.+", "\\1", Treatment), 
         MismTreat = gsub("\\w+(Day.+)", "\\1", Treatment),
         PupaWeight = PupaWeight_ingrams*1000) %>%
  # Keep only relevant columns:
  select(ExperimentName, MotherID, Treatment, PhotoTreat, MismTreat, 
         CaterpillarID, PupationAprilDay, PupaWeight) %>%
  # Remove caterpillars that did not pupate:
  filter(!is.na(PupationAprilDay)) %>%
  # Convert variables into factors for modelling:
  mutate(Treatment = as.factor(Treatment), 
         PhotoTreat = as.factor(ifelse(PhotoTreat == "Chang", "Changing", "Constant")), 
         MismTreat_factor = as.factor(MismTreat), 
         MotherID = as.factor(MotherID)) %>%
  # Order factor levels for treatments and get numeric version of mismatch day:
  mutate(Treatment_releveled = factor(Treatment, levels = c("ChangDay-4", "ChangDay-3", "ChangDay-2", "ChangDay-1",
                                                         "ChangDay0", "ChangDay+1", "ChangDay+2", "ChangDay+3", 
                                                         "ChangDay+4", "ChangDay+5",  "ConstDay-4", "ConstDay-2", 
                                                         "ConstDay0", "ConstDay+2", "ConstDay+4")), 
         MismTreat_factor = factor(MismTreat, levels = c("Day-4", "Day-3", "Day-2", "Day-1", "Day0",
                                                     "Day+1", "Day+2", "Day+3", "Day+4", "Day+5")),
         MismTreat = as.numeric(gsub("Day(.+)", "\\1", MismTreat))) %>%
  # Transform mismatch treatment so that lowest value is 1, to be able to fit the squared term. 
  # And add a column with a quadratic term:
  mutate(MismTreat_noNeg = MismTreat - min(MismTreat) + 1, 
         MismTreat_squared = (MismTreat - min(MismTreat) + 1)^2) 

# Check structure of cleaned data
head(cat_data_pupa)

# Tests after data manipulation
test_that("Pupa data table has correct class and dimensions", {
  expect_s3_class(cat_data_pupa, "data.frame")
  expect_equal(ncol(cat_data_pupa), 12)
  expect_equal(nrow(cat_data_pupa), nr_pupated)
})
test_that("Treatment_releveled reflects Treatment", {
  expect_true(all(cat_data_pupa$Treatment_releveled == cat_data_pupa$Treatment))})
test_that("MismTreat_squared equals MismTreat_noNeg squared", {
  expect_true(all(cat_data_pupa$MismTreat_squared == cat_data_pupa$MismTreat_noNeg^2))})
test_that("Caterpillar ID are unique", {
  expect_equal(length(unique(cat_data_pupa$CaterpillarID)), nrow(cat_data_pupa))})

# Calculate percentage of caterpillars that pupated
perc_pupated <- round(nrow(cat_data_pupa) / nrow(cat_data)*100, 2)


## Visualize raw pupation weight data -------------------------------------------------------------------------

# Summarize mean weight for each treatment
weight <- Rmisc::summarySE(cat_data_pupa, 
                           measurevar = "PupaWeight", 
                           groupvars = c("MismTreat", "PhotoTreat"))
# The warning message occurs because at Mismatch = -4 sample size is N = 1 for both treatments
# and standard deviations cannot be computed

# Set position of labels for each pupa weight 
weight$pos <- ifelse(is.na(weight$se) == T, 0, weight$se) 

# View pupation weights for each mismatch day
weight


## Raw pupation weight by mismatch day figure ----------------------------------------------------------------------------

raw_weight <- ggplot(data = weight, aes(x = MismTreat, y = PupaWeight, col = PhotoTreat, fill = PhotoTreat)) +
  scale_colour_manual(values = c("grey27", "orangered2")) +
  scale_fill_manual(values = c("grey27", "orangered2")) +
  # Add individual data points split by photoperiod:
  geom_jitter(data = cat_data_pupa, aes(col = PhotoTreat), alpha = 0.3, size = 3, height = 0, width = 0.25) +
  # Add error bars for each photoperiod group:
  geom_errorbar(data = filter(weight, PhotoTreat == "Changing"), aes(ymax = PupaWeight+se, ymin = PupaWeight-se), width = 0.3, col = "black") +
  geom_errorbar(data = filter(weight, PhotoTreat == "Constant"), aes(ymax = PupaWeight+se, ymin = PupaWeight-se), width = 0.3, col = "orangered4") +
  # Add mean value for each treatment:
  geom_point(size = 5, shape = 21, col = "black") +
  labs(y = "Weight at pupation (mg)", x = "Mismatch with oak budburst date (days)") +
  scale_y_continuous(breaks = seq(15, 75, by = 10)) + scale_x_continuous(breaks = seq(-4, 5, by = 1)) +
  theme(axis.title.y = element_text(size = 18, vjust = 2), axis.title.x = element_text(size = 18, vjust = -0.5),
        axis.text = element_text(size = 16), legend.text = element_text(size = 16), legend.title = element_text(size = 17))

# View figure
raw_weight  

# Save to outputs
if(save_figures) {
  ggsave(filename = "output/fig/PupWeight_raw.png", 
         plot = raw_weight, device = "png", 
         width = 200, height = 150, 
         units = "mm", dpi = "print")
}
 

## Fit linear mixed pupation weight model ---------------------------------------------------------

# Fit full linear mixed model for pupation weight, with a random effect for brood,
# fixed effects for mismatch treatment, mismatch treatment squared, and photoperiod,
# and interactions between mismatch and photoperiod treatments.
lmPupa_step1 <- lmerTest::lmer(PupaWeight ~ (MismTreat_noNeg + MismTreat_squared)*PhotoTreat + (1 | MotherID), 
                               data=cat_data_pupa)

# Check model assumptions
performance::check_model(lmPupa_step1)
# Line 20 is a clear outlier.

# Use ANOVA to check significance of covariates (here: interactions not significant)
anovaPupa_step1 <- anova(lmPupa_step1) %>% as.data.frame() 

# Label model
anovaPupa_step1$mod <- "lmPupa_step1"

# Refit without non-significant interactions
lmPupa_step2 <- update(lmPupa_step1, ~ . - MismTreat_noNeg:PhotoTreat - MismTreat_squared:PhotoTreat) 

# Test significance of updated model with ANOVA (here: squared mismatch not significant)
anovaPupa_step2 <- anova(lmPupa_step2) %>% as.data.frame() 
anovaPupa_step2$mod <- "lmPupa_step2"

# Refit without non-significant squared mismatch
lmPupa_step3 <- update(lmPupa_step2, ~ . - MismTreat_squared) 

# Test significance of updated model with ANOVA (here: both photoperiod and mismatch significant)
anovaPupa_step3 <- anova(lmPupa_step3) %>% as.data.frame() 
anovaPupa_step3$mod <- "lmPupa_step3"

# Refit without outlier (i.e. first mismatch day with low sample size) to check if it's still significant
lmPupa_step3_excludeOutlier <- lmerTest::lmer(PupaWeight ~ -1 + MismTreat_noNeg + PhotoTreat + (1 | MotherID), 
                                              data = filter(cat_data_pupa, MismTreat != -4))

# Check significance (here: same results when excluding outlier)
anova(lmPupa_step3_excludeOutlier) 

# Check model assumptions
performance::check_model(lmPupa_step3_excludeOutlier)

# Use the version including the first mismatch day as the final model
lmPupa_final <- lmPupa_step3

# Check model assumptions
performance::check_model(lmPupa_final)

# View model summary
summary(lmPupa_final)

# Extract estimated coefficients as dataframe
lmPupa_res <- summary(lmPupa_final)$coefficients %>% as.data.frame()

# Save model outputs
if(save_tables) {
  write.csv(lmPupa_res, 
            file = "output/result/output_PupaWeight_lmer.csv", row.names = T)
  write.csv(rbind(anovaPupa_step1, anovaPupa_step2, anovaPupa_step3), 
            file = "output/result/anova_PupaWeight_lmer.csv", row.names = T)
}


## Predict pupation weight -----------------------------------------------------------------------------

# Remove duplicate replicates (same brood will have the same predicted values)
lmPupa_pred <- cat_data_pupa[!duplicated(cat_data_pupa[, c("MotherID", "Treatment_releveled")]),] 

# Predict pupation weight 
lmPupa_pred$pred <- predict(lmPupa_final, newdata = lmPupa_pred, type = "response")

# View first rows of dataset
head(lmPupa_pred)


## Predicted pupation weight figure --------------------------------------------------------------------

# Get mean prediction and SEs for each treatment
pred_pupa <- Rmisc::summarySE(lmPupa_pred, measurevar = "pred", groupvars = c("MismTreat", "PhotoTreat")) 
# The warning message occurs because at Mismatch = -4 sample size is N = 1 for both treatments
# and standard deviations cannot be computed
pred_pupa$samplesize <- weight$N
pred_pupa$pos <- ifelse(is.na(pred_pupa$se) == T, 0, pred_pupa$se) # position of sample size labels

# Add predictions to raw weight figure
p_weight <- raw_weight + 
  geom_smooth(data = pred_pupa, aes(y = pred, col = PhotoTreat), se = F, method = lm) +
  # Add labels for sample size:
  geom_text(data = filter(weight, PhotoTreat == "Changing"), aes(label = N, y = PupaWeight-pos-1.5), col = "black", size = 4, fontface = "bold") +
  geom_text(data = filter(weight, PhotoTreat == "Constant"), aes(label = N, y = PupaWeight+pos+2.3), col = "black", size = 4, fontface = "bold")
p_weight

# Save the figure
if(save_figures) {
  ggsave(filename = "output/fig/PupWeight_wpred_rev.png",
    plot = p_weight, device = "png", 
    width = 200, height = 150,
    units = "mm", dpi = "print"
    )
}

# End of pupation weight analysis
## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


## Combine Survival and Pupation weight figures into one figure -------------------------------------------------------------------------------

# common_legend in ggarrange() does not work properly here (to get legend on the right)
# so we use a trick by combining ggpubr and cowplot
# we extract the legend, which is considered as a different figure
# then we arrange figure position with cowplot::plot_grid()
fig2_layout <- 
  ggpubr::ggarrange(p_surv + theme(legend.position = "none"),
                    p_weight + theme(legend.position = "none"), 
                    nrow = 1,
                    labels = c("(a)", "(b)"),
                    font.label = list(face = "italic")) 

fig2 <- 
  cowplot::plot_grid(fig2_layout, 
                     # extracting legend here
                     ggpubr::get_legend(p_weight), 
                     # to arrange positions
                     rel_widths = c(0.6, 0.1)) +
  bgcolor('white')

fig2

# Save the figure
if(save_figures) {
  ggsave(filename = "output/fig/figure_2.png",
         fig2, device = "png", 
         width = 400, height = 150, 
         units = "mm", dpi = "print")
}


## <Construct fitness curve> -------------------------------------------------------------------------------
# This section calculates the fitness curve for each mismatch day, looking at the combination
# of survival and pupation weight. New models are fit for these relationships, and 
# the resulting fitness curve is plotted.


## Refit models for fitness -------------------------------------------------------------------

# Refit models for weight and survival without the photoperiod effect (only mismatch and mismatch squared)
modelSurv_fitness <- lme4::glmer(survival ~ MismTreat_noNeg + MismTreat_squared + (1 | MotherID), 
                                 family = "binomial",
                                 data = cat_data_surv)

modelPupa_fitness <- lmerTest::lmer(PupaWeight ~ MismTreat_noNeg + (1 | MotherID), data = cat_data_pupa)

# Get predictions of survival for fitness curve
# Remove duplicates for each brood since all have same prediction
predSurv_fitness <- cat_data_surv[!duplicated(cat_data_surv[, c("MotherID", "MismTreat_factor")]),] 

# Predict probability of dying
predSurv_fitness$pred <- predict(modelSurv_fitness, newdata = predSurv_fitness, type = "response") 

# Invert to survival probability
predSurv_fitness$survpred <- (1 - predSurv_fitness$pred)

# Get predictions of weight for fitness curve
# Remove duplicates for each brood since all have same prediction
predPupa_fitness <- cat_data_pupa[!duplicated(cat_data_pupa[, c("MotherID", "MismTreat_factor")]),] 
nrow(predPupa_fitness) # 154 clutches with >=1 caterpillar surviving until pupation

# Predict weight
predPupa_fitness$pred <- predict(modelPupa_fitness, newdata = predPupa_fitness, type = "response")

# Check prediction sample size
test_that("220 observations = 22 mothers * 10 MismTreat groups", {expect_equal(!is.na(predSurv_fitness$pred), 220)})
test_that("154 predicted weights", {expect_equal(!is.na(predPupa_fitness$pred), 154)})

# View first rows of each set of predictions
head(predSurv_fitness) # pred = probability of dying, survpred = 1 - pred, 
head(predPupa_fitness) # pred = pupation weight


## Fitness analysis --------------------------------------------------------------------------

# Combine weight and survival predictions
RelFit <- merge(predSurv_fitness[, c("MotherID", "MismTreat", "survpred")],
                predPupa_fitness[, c("MotherID", "MismTreat", "pred")], 
                by = c("MotherID", "MismTreat"), all = T)
RelFit <- RelFit %>% rename(pred = pupwpred)

# Multiply absolute weight and survival
RelFit$RelFit_NonNul <- RelFit$survpred * RelFit$pupwpred 

# For clutches with no caterpillars surviving until pupation, fitness = 0
RelFit$Fit <- ifelse(is.na(RelFit$RelFit_NonNul) == T, 0, RelFit$RelFit_NonNul)

# Fit a loess model to describe the fitness curve
loess_mod <- loess(Fit ~ -1 + MismTreat, data = RelFit) 
summary(loess_mod)

# Get predicted fitness curve, starting with index of mismatch days
curve <- RelFit[!duplicated(RelFit[, c("MismTreat")]),] %>% select(MismTreat)

# Add predictions from loess model
curve$pred <- predict(loess_mod, newdata = curve)
curve <- curve %>% arrange(MismTreat)

# Calculate relative fitness compared to peak
MismTreat_FitPeak <- curve$MismTreat[curve$pred == max(curve$pred)] 
curve$rel <- curve$pred / filter(curve, MismTreat == MismTreat_FitPeak)$pred 

RelFit$rel <- RelFit$Fit / mean(filter(RelFit, MismTreat == MismTreat_FitPeak)$Fit)

# Get mean relative fitness for each mismatch day
RelFit_means <- Rmisc::summarySE(RelFit, measurevar = "rel", groupvars = c("MismTreat"))

# Get sample sizes (number of caterpillars)
RelFit_means$samplesize <- aggregate(MotherID ~ MismTreat, data = cat_data_surv, length)$MotherID 
RelFit_means$curve <- curve$rel

# View first rows
head(RelFit_means)

# Save RelFit_means
if(save_tables) { 
  write.csv(RelFit_means, file = "output/result/RelFitness_rev.csv", row.names = F)
}
 

## Relative fitness curve figure ---------------------------------------------------------------------

p_relfit <- ggplot(data = RelFit, aes(x = MismTreat, y = rel)) +
 # Add relative fitness data points:
  geom_jitter(size = 3, alpha = 0.4, height = 0, width = 0.25, shape = 21, fill = "dodgerblue2", col = "dodgerblue4") +
  # Add mean values:
  geom_point(data = RelFit_means, size = 5) +
  # Add error bars:
  geom_errorbar(data = RelFit_means, aes(ymax = rel+se, ymin = rel-se), width = 0.3) +
  # Add sample size labels:
  geom_text(data = RelFit_means, aes(label = samplesize, y = rel+0.12), col = "black", size = 5, fontface = "bold") +
  geom_hline(yintercept = 1, linetype = "dashed") +
  labs(y = "Relative fitness", x = "Mismatch with oak budburst date (days)") +
  scale_y_continuous(lim = c(0, max(RelFit$rel)), breaks = seq(0, 1.6, by = 0.2)) + 
  scale_x_continuous(breaks = seq(-4, 5, by = 1)) +
  theme(legend.position = "none") +
  theme(axis.title.y = element_text(size = 18, vjust = 2), axis.title.x = element_text(size = 18, vjust = -0.5),
        axis.text = element_text(size = 16), legend.text = element_text(size = 16), legend.title = element_text(size = 17))

# View figure
p_relfit

# Save the figure
if(save_figures) {
  ggsave(
    filename = "output/fig/FitnessCurve_rev.png",
    plot = p_relfit, device = "png",
    width = 200, height = 150, 
    units = "mm", dpi = "print"
    )
}


## Calculate average fitness loss per day  -------------------------------------------
# NB: in the original analysis these values were calculated in a not-deposited excel
#     thus not reproducible nor code-based

## Hatching earlier than budburst
fitness_loss_hatchedEarlier <- RelFit_means %>%
  select(MismTreat, curve) %>%
  filter(MismTreat <= MismTreat_FitPeak) %>%
  rename("pred_fitness" = "curve") %>%
  # What would have been the mean fitness if hatched one day later?
  mutate(lagged_fitness = lead(pred_fitness)) %>%
  mutate(fitness_loss = lagged_fitness - pred_fitness)

# Check output
print(fitness_loss_hatchedEarlier)

# Calculate mean fitness loss -> Should be 14%
mean_fitness_loss_earlier <- exp(mean(log(fitness_loss_hatchedEarlier$fitness_loss), na.rm = TRUE)) %>% round(2)
#checkReproducibilityValues(mean_fitness_loss_earlier, 0.14)
test_that("Mean fitness loss before budburst equals 0.14", {expect_equal(mean_fitness_loss_earlier, 0.14)})

# Calculate max fitness loss -> Should be 32%
fitness_loss_hatchedEarlier %>% dplyr::slice(which.max(fitness_loss)) # corresponds to day -1
max_fitness_loss_earlier <- max(fitness_loss_hatchedEarlier$fitness_loss, na.rm = TRUE) %>% round(2)
#checkReproducibilityValues(max_fitness_loss_earlier, 0.32)
test_that("Max fitness loss before budburst equals 0.32", {expect_equal(max_fitness_loss_earlier, 0.32)})


## Hatching later than budburst
fitness_loss_hatchedLater <- RelFit_means %>%
  select(MismTreat, curve) %>%
  filter(MismTreat >= MismTreat_FitPeak) %>%
  rename(pred_fitness = curve) %>%
  # What would have been the mean fitness if hatched one day later?
  mutate(lagged_fitness = lag(pred_fitness)) %>%
  mutate(fitness_loss = lagged_fitness - pred_fitness)

# Check output
print(fitness_loss_hatchedLater)

# Calculate mean fitness loss -> Should be 13% (although reported as 6% in paper)
mean_fitness_loss_later <- exp( mean( log(fitness_loss_hatchedLater$fitness_los), na.rm = TRUE) ) %>% round(2)
# necessary to do log() %>% mean() %>% exp()? Cannot just use mean()?
#checkReproducibilityValues(mean_fitness_loss_Later, 0.13)
test_that("Mean fitness loss after budburst equals 0.13", {expect_equal(mean_fitness_loss_later, 0.13)})

# Calculate max fitness loss -> Should be 24%
fitness_loss_hatchedLater %>% dplyr::slice(which.max(fitness_loss)) # corresponds to day -1
max_fitness_loss_later <- fitness_loss_hatchedLater$fitness_loss %>% max(na.rm = TRUE) %>% round(2)
#checkReproducibilityValues(max_fitness_loss_Later, 0.24)
test_that("Max fitness loss after budburst equals 0.24", {expect_equal(max_fitness_loss_later, 0.24)})


## Save output tables
if(save_tables) {
  write.csv(fitness_loss_hatchedEarlier, file="output/fitness_loss_hatchedEarlier.csv")
  write.csv(fitness_loss_hatchedLater, file="output/fitness_loss_hatchedLater.csv")
}
# NB: make sure also the day of max fitness loss is reported!
# + Combine into one table