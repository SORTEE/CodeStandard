## Analysis of Phenological mismatch experiment 2021 
#
# In this study, caterpillar eggs were taken from wild mothers caught in 2020. Timing of egg hatching
# was manipulated, with eggs either hatching on the day of budburst (Day0), before (Day-4 to -1),
# or after (Day+1 to +5). The photoperiod was also manipulated, with either a constant or changing
# photoperiod.
#
# To run this down, download the dataset 'CatFood2021_deposit.csv' from Dryad repository: 
# https://doi.org/10.5061/dryad.m905qfv5p
#
# The dataset should be saved in the folder Data/
# Open the R project in the main folder of this repository.


# Setup ---------------------------------------------------------------------------------------
# This section loads the required packages, reads in the data required for the analysis, and
# provides some simple summaries of the data structure.

## Load R environment --------------------------------------------------------------------------
# This restores the versions of packages used in the original analysis.
renv::restore()

# If error when downloading digest :
  # (this happens, check https://stackoverflow.com/questions/48548767/can-not-download-digest-package-in-r)
if(!require(digest))
  install.packages('digest', repos = 'http://cran.us.r-project.org')

# Setting seed for random processes
set.seed(147)

## Load packages -------------------------------------------------------------------------------

library(Rmisc)             # Used for calculating standard error and confidence intervals for data summaries
library(rdryad)            # Used to download the data
library(tidyverse)         # Used for data cleaning and manipulation.
library(cowplot)           # Used for creating and arranging plots, providing a clean theme for publication
theme_set(theme_cowplot()) # Use white background instead of grey
library(lme4)              # Used for fitting linear and generalized linear mixed-effects models (LMMs and GLMMs)
library(lmerTest)          # Provides p-values for LMMs and GLMMs using Satterthwaite's approximation
library(performance)       # Used to check model's assumption
library(testthat)          # Used to unit tests
library(ggpubr)            # Used to arrange multiple figures


# Load functions  -------------------------------------------------------------------------------

pathF <- c("2_scripts/Functions/") # They are stored here
functions <- list.files(pathF)
sapply(functions, function(file) source(paste0(pathF, file))) %>% invisible


# Checking file presence for reproducibility checks ---------------------------------------------

# To verify that reference files for reproducibility checking are present
checkReferenceFilePresence()
  To verify that outputs were already saved and stored in "_results" folder
checkOutputPresence()


# User configuration ----------------------------------------------------------------------------

# set to TRUE to save figures (as .png files)
save_figures <- FALSE
# set to TRUE to save tables (as .csv files)
save_tables <- FALSE
# set to TRUE to save reference outputs (as .rds files)
save_ref_outputs <- FALSE
# set to TRUE to read reference outputs for comparison
read_ref_outputs <- FALSE
# set to TRUE to save session info again
save_session_info <- FALSE

# this creates output directory if saving is enabled
if (save_figures | save_tables && !dir.exists("_results")) {
  dir.create("_results")
}

if (save_ref_outputs && !dir.exists("_results/ref")) {
  dir.create("_results/ref")
}

# Create folders to store data and results -----------------------------------------------------
sapply(c("1_data", "_results"),
       function(i) 
         if (! dir.exists(i)) dir.create(i))

# Download data from dryad repository ----------------------------------------------------------

# Check if data is present in folder
file_name <- "CatFood2021_deposit.csv"
file_path <- file.path("1_data", file_name)
file_exists <- file.exists(file_path)

# If not, automatically download it from Dryad
  # -> that way, this does not require user input
if(file_exists == F) {
  # Download dryad repo in rdryad cache
  doi <- "10.5061/dryad.m905qfv5p"
  tmp_files <- rdryad::dryad_download(doi)[[doi]]

  # Copy desired file to data folder
  file.copy(tmp_files[grepl(file_name, tmp_files)], 
          "1_data", 
          overwrite = TRUE)
  
}

## Load data -----------------------------------------------------------------------------------
# Load data for analysis. This must be downloaded from the Dryad repository prior to running
cat_data_raw <- read.csv("1_data/CatFood2021_deposit.csv")
test_that("raw data table has correct class and dimensions", {
  expect_s3_class(cat_data_raw, "data.frame")
  expect_equal(ncol(cat_data_raw), 19)
  expect_equal(nrow(cat_data_raw), 976)
})


# Checks number of missing data consistent with article
test_that("346 pupated", {expect_equal(sum(is.na(cat_data_raw$DeadAprilDay)),346)})
test_that("630 died before pupation", {
  expect_equal(sum(is.na(cat_data_raw$PupationAprilDay)),630)
  expect_equal(sum(is.na(cat_data_raw$PupaWeight_ingrams)),630)
})
test_that("962 died before adulthood", {
  expect_equal(sum(is.na(cat_data_raw$AdultNovDate)),962)
  expect_equal(sum(is.na(cat_data_raw$AdultWeight_ingrams)),962)
  expect_equal(sum(is.na(cat_data_raw$Sex)),962)
})

## Data summary -------------------------------------------------------------------------------
# Quick checks of the data's structure

# should print the first 6 rows and the 19 columns
head(cat_data_raw) 
summary(cat_data_raw)

# Check for outliers
# Histograms should not show any outliers
hist(cat_data_raw$NovemberDate)
hist(cat_data_raw$PupaWeight_ingrams)
hist(cat_data_raw$DeadAprilDay)
hist(cat_data_raw$PupationAprilDay)
hist(cat_data_raw$PupaWeight_ingrams)
hist(cat_data_raw$AdultNovDate)
hist(cat_data_raw$AdultWeight_ingrams)

# renaming TubeID as MotherID to match the terminology used in the Statistical section of the paper
cat_data <- rename(cat_data_raw, MotherID = TubeID)

test_that("22 different mothers", {expect_equal(length(unique(cat_data$MotherID)), 22)})
test_that("15 treatment values", {expect_equal(length(unique(cat_data$Treatment)), 15)})
table(cat_data$Treatment) # photoperiod and mismatch treatment coded in one variable

# Expected n = 22 clutches × 15 treatments × 3 replicates = 990
str(d)
# Actual n = 976 → missing 14 individuals
# The `Tree` column in this dataset refers to the tree ID where the mother moth was caught as per the long-term field data collection described in the paper.
xtabs(~ Treatment + MotherID, data = d)
# specific clutch × treatment combinations with < 3 individuals:
# e.g., ConstDay0 × MotherID=16612 has 0; several others have 2 instead of 3
# some individuals lacked survival or weight data

# Photoperiod and mismatch treatment coded in one variable
table(d$Treatment) 

# N per Area
table(cat_data[!duplicated(cat_data$MotherID), "AreaShortName"])
# should match the counts given in section 2.b Phenological mismatch experiment

# Survival analysis ----------------------------------------------------------------------------
# This section analyses the consequences of day-to-day timing a(synchronoy) with budburst on the 
# survival of caterpillars. The data is first prepared, then the raw survival data is plotted. 
# Generalised linear models are then fit to model the influence of treatment on survival, and the
# predicted survival based on these models is plotted.


## Survival data preparation ------------------------------------------------------------------


# The following section reshapes and cleans the data to prepare it for survival analysis
cat_data_surv <- cat_data %>% 
  # Separate the two components of treatment (Photoperiod and mismatch period)
  mutate(PhotoTreat=gsub("(\\w+)Day.+","\\1",Treatment), 
  MismTreat=gsub("\\w+(Day.+)","\\1",Treatment)) %>% 
  # Remove extraneous columns
  select(MotherID, Treatment, PhotoTreat, MismTreat, 
         CaterpillarID, DeadAprilDay, PupationAprilDay) %>% 
  # Move the death and pupation dates into long format
  # This is necessary to create a "survival" variable that indicates whether the caterpillar died or survived to pupate
  pivot_longer(cols=c(DeadAprilDay, PupationAprilDay),
               names_to="Info", values_to="TimeOfDeath") %>%
  filter(!is.na(TimeOfDeath)) %>%
  # The `survival` variable is created as a binary indicator for the binomial mixed model
  # It is coded as 1 for death (`DeadAprilDay`) and 0 for survival (`PupationAprilDay`)
  mutate(survival=ifelse(Info=="DeadAprilDay", 1, 0)) %>% 
  # Coerce columns to factors 
  mutate(Treatment = as.factor(Treatment), 
         PhotoTreat = as.factor(ifelse(PhotoTreat == "Chang", "Changing", "Constant")), 
         MismTreatf = as.factor(MismTreat), 
         MotherID = as.factor(MotherID)) %>%
  # Order factor levels, adding numeric and factor versions of mismatch treatment      
  mutate(Treatment_relevelled=factor(Treatment, levels=c("ChangDay-4", "ChangDay-3", "ChangDay-2",
                                                         "ChangDay-1", "ChangDay0", "ChangDay+1", 
                                                         "ChangDay+2", "ChangDay+3", "ChangDay+4",
                                                         "ChangDay+5",  "ConstDay-4", "ConstDay-2", 
                                                         "ConstDay0", "ConstDay+2", "ConstDay+4")), 
         MismTreat_factor=factor(MismTreat, levels=c("Day-4", "Day-3", "Day-2", "Day-1", "Day0", 
                                                     "Day+1", "Day+2", "Day+3", "Day+4", "Day+5")),
         MismTreat=as.numeric(gsub("Day(.+)","\\1",MismTreat))) %>%
  # Transformed so that lowest value is 1, to be able to fit the squared term. And add a column with a quadratic term
  mutate(MismTreat_noNeg=MismTreat-min(MismTreat)+1, 
         MismTreat_squared=(MismTreat-min(MismTreat)+1)^2) 

test_that("survival data table has correct class and dimensions", {
  expect_s3_class(cat_data_surv, "data.frame")
  expect_equal(ncol(cat_data_surv), 12)
  expect_equal(nrow(cat_data_surv), 976)
})

test_that("Treatment_relevelled reflects Treatment", {expect_true(all(cat_data_surv$Treatment_relevelled == cat_data_surv$Treatment))})
test_that("MismTreat_squared equals MismTreat_noNeg squared", {expect_true(all(cat_data_surv$MismTreat_squared == cat_data_surv$MismTreat_noNeg^2))})
test_that("Caterpillar ID are unique", {expect_equal(length(unique(cat_data_surv$CaterpillarID)), nrow(cat_data_surv))})

# View first rows of processed data
head(cat_data_surv) 

levels(cat_data_surv$Treatment_relevelled)
levels(cat_data_surv$PhotoTreat)
levels(cat_data_surv$MismTreat_factor) 
levels(cat_data_surv$MotherID)
# 'TimeOfDeath' is date of either death or pupation
table(cat_data_surv$TimeOfDeath)
# 'survival' is the response variable (e.g., whether the caterpillar died or not) 
table(cat_data_surv$survival) 


## Survival analysis --------------------------------------------------------------------------

# Get the number of deaths in each brood
surv_probs <- aggregate(survival~MismTreat + PhotoTreat + MotherID, cat_data_surv, sum)

# Add the number of individuals in each brood
surv_probs$samplesize <- aggregate(Info~MismTreat + PhotoTreat + MotherID, cat_data_surv, length)$Info

# Calculate the proportion of caterpillars surviving
surv_probs$probs <- 100 - (surv_probs$survival/surv_probs$samplesize*100) 

# View first few rows
head(surv_probs)

# Take the average survival rate for each mismatch period (averaged between both photoperiod treatments)
surv_avg <- Rmisc::summarySE(surv_probs, measurevar="probs", groupvars=c("MismTreat")) 

# Add sample size
surv_avg$samplesize <- aggregate(Info~MismTreat, cat_data_surv, length)$Info

# View survival rates for each mismatch period
surv_avg

## Survival figure ----------------------------------------------------------------------------

# Render figure of survival rate by mismatch date
raw_surv <- ggplot(data=surv_avg, aes(x=MismTreat, y=probs))+
  scale_colour_manual(values=c("grey27", "orangered2"))+ #"dodgerblue4"
  # Add transparent points for the survival rates split by photoperiod
  geom_jitter(data=surv_probs, aes(col=PhotoTreat), alpha=0.3, size=3, height=0.5, width=0.25)+
  # Add points, errorbars, and labels for the mean survival by date
  geom_point(size=5, col="black") +
  geom_errorbar(aes(ymax = probs+se, ymin=probs-se), width=0.3, col="black") +
  geom_text(aes(label=samplesize, y=probs+8.3), col="black", size=4,fontface="bold")+ # N caterpillars in each treatment
  labs(y="Survival (%)", x="Mismatch with oak budburst date (days)")+
  scale_y_continuous(breaks=seq(0,100, by=10))+ scale_x_continuous(breaks=seq(-4, 5, by=1))+
  theme(axis.title.y=element_text(size=18, vjust=2), axis.title.x=element_text(size=18, vjust=-0.5),
        axis.text=element_text(size=16), legend.text = element_text(size=16), legend.title=element_text(size=17))

# View figure
raw_surv 

# Save to outputs
if(save_figures)
  ggsave(filename="_results/Survival_raw.png",
         plot=raw_surv , device="png",
         width=200, height=150, 
         units="mm", dpi="print")

## Fit binomial survival model -----------------------------------------------------------------

# Fit generalised linear mixed model for probability of death, with a random effect for brood,
# fixed effects for mismatch treatment, mismatched treatment squared, and photoperiod, and an
# interaction between mismatch and photoperiod treatments.
glmSurv_step1 <- lme4::glmer(survival ~ (MismTreat_noNeg + MismTreat_squared)*PhotoTreat + (1|MotherID), 
                             family=binomial, 
                             data=cat_data_surv,
                             na.action="na.fail",
                             control=glmerControl(calc.derivs=F)) # helps convergence
# Check model assumptions
check_model(glmSurv_step1)

# Use ANOVA to identify non-significant terms (In this case, both interactions)
anovaSurv_step1 <- drop1(glmSurv_step1,test="Chi") %>% as.data.frame() 

# The interaction terms are removed here because their p-values were not significant in the `glm1` model
# Refit the model without the interactions 
glmSurv_step2 <- update(glmSurv_step1, ~ . -MismTreat_noNeg:PhotoTreat - MismTreat_squared:PhotoTreat) 

# Test significance of updated model with ANOVA 
# (Photoperiod not significant, but both mismatch treatment covariates are)
anovaSurv_step2 <- drop1(glmSurv_step2,test="Chi") %>% as.data.frame()
# Label updated model
anovaSurv_step2$mod <- "glmSurv_step2"

# Use the model without interactions as the final model
glmSurv_final <- glmSurv_step2

# Check model assumptions
check_model(glmSurv_final)

# Estimates are log odds
summary(glmSurv_final)

# Extract estimated coefficients as dataframe
glmSurv_res <- summary(glmSurv_final)$coefficients %>% as.data.frame

# Save model outputs
if(save_tables) {
  write.csv(glm_res, file="_results/output_Surv_glmer.csv", row.names=T)
  write.csv(rbind(anova1, anova2), file="_results/anova_Surv_glmer.csv", row.names=T)
}

## Predict survival ---------------------------------------------------------------------------

# Remove duplicate replicates
glmSurv_pred <- cat_data_surv[!duplicated(cat_data_surv[,c("MotherID", "Treatment_relevelled")]),] 

# Predict the probability of death
glmSurv_pred$pred <- predict(glmSurv_final, newdata=glmSurv_pred, type="response") 

# Invert to get probability of survival
glmSurv_pred$survprob <- (1-glmSurv_pred$pred)

# View predicted survival probability by day (peaks at Day 2)
SurvByMismTreat <- aggregate(survprob~MismTreat, data=glmSurv_pred, mean)

# Calculate survival probability relative to peak
MismTreat_SurvPeak <- SurvByMismTreat$MismTreat[SurvByMismTreat$survprob == max(SurvByMismTreat$survprob)] 
glmSurv_pred$rel <- glmSurv_pred$survprob/mean(filter(glmSurv_pred, MismTreat==MismTreat_SurvPeak)$survprob) 

# View first rows of dataset
head(glmSurv_pred)

## Predicted survival figure ------------------------------------------------------------------


# Visualize predictions 
# Get predicted daily survival, averaged across both photoperiods
pred_surv <- Rmisc::summarySE(glmSurv_pred, measurevar="survprob", groupvars=c("MismTreat")) 
pred_surv$samplesize <- aggregate(CaterpillarID~MismTreat, data=cat_data_surv, length)$CaterpillarID

# Add predictions to raw data figure
p_surv <- raw_surv + #geom_line(data=pred, aes(y=survprob*100)) +
  geom_smooth(data=pred_surv, aes(y=survprob*100), se=FALSE, colour="red3")

# View plot
p_surv

# Save the figure
if(save_figures)
  ggsave(filename="_results/Survival_wpred_rev.png", plot=p_surv, device="png", width=200, height=150, units="mm", dpi="print")

# Save it as the reference file for reproducibility tests
if(save_ref_outputs)
  write_rds(p_surv, "_results/ref/p_surv_expected.rds")

# Check correspondence with saved figure (reference)
checkReproducibilityOutput(obtained = p_surv, 
                           ref_path = "_results/ref/p_surv_expected.rds", # the expected figure saved as a .RDS
                           ref_vis = "_resultsSurvival_wpred_rev.png", # the expected figure saved as a .PNG
                           print = F)

# Read the reference file for visual comparison
if(read_ref_outputs) readReferenceFile("p_surv")

## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# 5. Pupation weight analysis ####

# Pupation weight analysis --------------------------------------------------------------------
# This section analyses the impact of mismatch date and photoperiod on weight at pupation. 
# GLMs are fit to identify significant covariates, and plots of the relationships are rendered.


## Pupation data preparation ------------------------------------------------------------------

# Manipulate into long format suitable for modelling
cat_data_pupa <- cat_data %>%
  # Split treatment into its components (mismatch date and photoperiod)
  mutate(PhotoTreat=gsub("(\\w+)Day.+","\\1",Treatment), 
         MismTreat=gsub("\\w+(Day.+)","\\1",Treatment),
         PupaWeight=PupaWeight_ingrams*1000) %>%
  # Select only meaningful columns
  select(ExperimentName, MotherID, Treatment, PhotoTreat, MismTreat, 
         CaterpillarID, PupationAprilDay, PupaWeight) %>%
  # Remove caterpillars that did not pupate
  filter(!is.na(PupationAprilDay)) %>%
  # Convert variables into factors for modelling
  mutate(Treatment=as.factor(Treatment), 
         PhotoTreat=as.factor(ifelse(PhotoTreat=="Chang", "Changing", "Constant")), 
         MismTreat_factor=as.factor(MismTreat), 
         MotherID=as.factor(MotherID)) %>%
  # Set factor levels for treatments in appropriate order and get numeric version of mismatch date
  mutate(Treatment_relevelled=factor(Treatment, levels=c("ChangDay-4", "ChangDay-3", "ChangDay-2", "ChangDay-1",
                                                         "ChangDay0", "ChangDay+1", "ChangDay+2", "ChangDay+3", 
                                                         "ChangDay+4", "ChangDay+5",  "ConstDay-4", "ConstDay-2", 
                                                         "ConstDay0", "ConstDay+2", "ConstDay+4")), 
         MismTreat_factor=factor(MismTreat, levels=c("Day-4", "Day-3", "Day-2", "Day-1", "Day0",
                                                     "Day+1", "Day+2", "Day+3", "Day+4", "Day+5")),
         MismTreat=as.numeric(gsub("Day(.+)","\\1",MismTreat))) %>%
  # Transformed so that lowest value is 1, to be able to fit the squared term. And add squared term for modelling
  mutate(MismTreat_noNeg=MismTreat-min(MismTreat)+1, 
         MismTreat_squared=(MismTreat-min(MismTreat)+1)^2) 

## tests after data manipulaiton ----
test_that("pupa data table has correct class and dimensions", {
  expect_s3_class(cat_data_pupa, "data.frame")
  expect_equal(ncol(cat_data_pupa), 12)
  expect_equal(nrow(cat_data_pupa), 346) # 346 individuals survived until pupation
})

test_that("Treatment_relevelled reflects Treatment", {expect_true(all(cat_data_pupa$Treatment_relevelled == cat_data_pupa$Treatment))})
test_that("MismTreat_squared equals MismTreat_noNeg squared", {expect_true(all(cat_data_pupa$MismTreat_squared == cat_data_pupa$MismTreat_noNeg^2))})
test_that("Caterpillar ID are unique", {expect_equal(length(unique(cat_data_pupa$CaterpillarID)), nrow(cat_data_pupa))})

## Pupation analysis --------------------------------------------------------------------------

# View first rows of processed data
head(cat_data_pupa)

# Check number of individuals that survived to pupation (346)
nrow(cat_data_pupa)

# Check percentage that pupated (35.45)
nrow(cat_data_pupa)/nrow(cat_data)*100 

## Pupa weight figure -------------------------------------------------------------------------

# Summarise mean weight for each treatment (some SEs not calculated as n=1 for some treatments)
weight <- Rmisc::summarySE(cat_data_pupa, 
                           measurevar="PupaWeight", 
                           groupvars=c("MismTreat", "PhotoTreat"))
# The warning message occurs because at Mismatch = -4 sample size is N = 1 for both treatments
# and standard deviations cannot be computed

# Set position of labels for each pupa weight 
weight$pos <- ifelse(is.na(weight$se)==T, 0, weight$se) 
# View summary
weight


# Render figure of pupation weight by treatment
raw_weight <- ggplot(data=weight, aes(x=MismTreat, y=PupaWeight, col=PhotoTreat, fill=PhotoTreat))+
  scale_colour_manual(values=c("grey27", "orangered2"))+ #"dodgerblue4"
  scale_fill_manual(values=c("grey27", "orangered2"))+
  # Add individual data points
  geom_jitter(data=cat_data_pupa, aes(col=PhotoTreat), alpha=0.3, size=3, height=0, width=0.25)+ #alpha=0.3, size=2, height=0, width=0.25
  # Add error bars for each photoperiod group
  geom_errorbar(data=filter(weight, PhotoTreat=="Changing"), aes(ymax = PupaWeight+se, ymin=PupaWeight-se), width=0.3, col="black") +
  geom_errorbar(data=filter(weight, PhotoTreat=="Constant"), aes(ymax = PupaWeight+se, ymin=PupaWeight-se), width=0.3, col="orangered4") +
  # Add mean value for each treatment
  geom_point(size=5, shape=21, col="black")+
  # Add labels for sample size
  #geom_text(data=filter(weight, PhotoTreat=="Changing"),aes(label=N, y=PupaWeight-pos-2.3), col="black", size=4, fontface="bold")+
  #geom_text(data=filter(weight, PhotoTreat=="Constant"),aes(label=N, y=PupaWeight+pos+2.3), col="black", size=4, fontface="bold")+
  labs(y="Weight at pupation (mg)", x="Mismatch with oak budburst date (days)")+
  scale_y_continuous(breaks=seq(15,75, by=10))+ scale_x_continuous(breaks=seq(-4, 5, by=1))+
  theme(axis.title.y=element_text(size=18, vjust=2), axis.title.x=element_text(size=18, vjust=-0.5),
        axis.text=element_text(size=16), legend.text = element_text(size=16), legend.title=element_text(size=17))

# View figure
raw_weight  

# Save the figure
if(save_figures)
  ggsave(filename="_results/PupWeight_raw.png", 
         plot=raw_weight, 
         device="png", 
         width=200, 
         height=150, 
         units="mm", 
         dpi="print")

## Fit linear mixed model for weight ---------------------------------------------------------

# Fit full linear mixed model with fixed effects for mismatch date, mismatch date squared, and photoperiod,
# interactions between mismatch date and photoperiod, and a random effect for brood
lmPupa_step1 <- lmerTest::lmer(PupaWeight ~ (MismTreat_noNeg + MismTreat_squared)*PhotoTreat + (1|MotherID), data=cat_data_pupa)

# Check model assumptions
check_model(lmPupa_step1)
# Line 20 is a clear outlier.

# Check significance of covariates (interactions not significant)
anovaPupa_step1 <- anova(lmPupa_step1) %>% as.data.frame() 

# Label anova
anovaPupa_step1$mod <- "lmPupa_step1"

# Refit without interactions
lmPupa_step2 <- update(lmPupa_step1, ~ . - MismTreat_noNeg:PhotoTreat - MismTreat_squared:PhotoTreat) 
## Check significance again (squared mismatch not significant)
anovaPupa_step2 <- anova(lmPupa_step2) %>% as.data.frame() 

# Label anova
anovaPupa_step2$mod <- "lmPupa_step2"

# Refit without squared mismatch
lmPupa_step3 <- update(lmPupa_step2, ~ . - MismTreat_squared) 
# Check significance again (both photoperiod and mismatch significant)
anovaPupa_step3 <- anova(lmPupa_step3) %>% as.data.frame() 
anovaPupa_step3$mod <- "lmPupa_step3"

# Refit without first period with low sample size to check if it's still significant
lmPupa_step3_excludeOutlier <- lmerTest::lmer(PupaWeight ~ -1 + MismTreat_noNeg + PhotoTreat + (1|MotherID), 
                                              data=filter(cat_data_pupa, MismTreat!=-4))

# Check significance (Still good without first timestep)
anova(lmPupa_step3_excludeOutlier) 

# Check model assumptions
check_model(lmPupa_step3_excludeOutlier)

# Use the version with the first time-step included for the final model
lmPupa_final <- lmPupa_step3

# Check model assumptions
check_model(lmPupa_final)

# View model summary
summary(lmPupa_final)

# Get results
lmPupa_res <- summary(lmPupa_final)$coefficients %>% as.data.frame()

# Save model outputs
if(save_tables) {
  write.csv(lm_res, 
            file="_results/output_PupaWeight_lmer.csv", row.names=T)
  write.csv(rbind(anova1, anova2, anova3), 
            file="_results/anova_PupaWeight_lmer.csv", row.names=T)
}

## Predict weight -----------------------------------------------------------------------------

# Remove duplicates from same brood, since all will have the same prediction
lmPupa_pred <- cat_data_pupa[!duplicated(cat_data_pupa[,c("MotherID", "Treatment_relevelled")]),] 

# Predict pupation weight for each 
lmPupa_pred$pred <- predict(lmPupa_final, newdata=lmPupa_pred, type="response")

# View first rows
head(lmPupa_pred)

## Predicted weight figure --------------------------------------------------------------------
# Get mean prediction and SEs for each treatment - some have NA standard errors due to sample size
pred_pupa <- Rmisc::summarySE(lmPupa_pred, measurevar="pred", groupvars=c("MismTreat", "PhotoTreat")) 
## The warning message occurs because at Mismatch = -4 sample size is N = 1 for both treatments
# and standard deviations cannot be computed
pred_pupa$samplesize <- weight$N
pred_pupa$pos <- ifelse(is.na(pred_pupa$se)==T, 0, pred_pupa$se) # position of sample size labels

# Add predictions to raw weight figure
p_weight <- raw_weight + #geom_line(data=pred_pupa, aes(y=pred)) +
  geom_smooth(data=pred_pupa, aes(y=pred, col=PhotoTreat), se=F, method=lm)+
  geom_text(data=filter(weight, PhotoTreat=="Changing"),aes(label=N, y=PupaWeight-pos-1.5), col="black", size=4, fontface="bold")+
  geom_text(data=filter(weight, PhotoTreat=="Constant"),aes(label=N, y=PupaWeight+pos+2.3), col="black", size=4, fontface="bold")
p_weight

# Save the figure
if(save_figures)
  ggsave(filename="_results/PupWeight_wpred_rev.png", plot=p_weight, device="png", width=200, height=150, units="mm", dpi="print")

# Fitness curve -------------------------------------------------------------------------------
# This section calculates the fitness curve for each mismatch date, looking at the combination
# of survival and pupation weight. New models are fit for these relationships, and the resulting fitness
# curve is plotted.

# Making figure 2 entirely code-based
# common_legend in ggarrange() does not work properly here
  # (to get legend on the right)
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

  # sate save_figures to TRUE to save the figure again
if(save_figures) 
  ggplot2::ggsave(filename = "_results/figure_2.png",
                  fig2, 
                  device = "png", 
                  width = 400, 
                  height = 150, 
                  units = "mm", 
                  dpi = "print")

  # sate save_ref_outputs to TRUE to save it as a reference file
  # for reproducibility checking
if(save_ref_outputs)
  write_rds(fig2, file = "_results/ref/fig2_expected.rds")

# Checking reproducibility
  # !! CheckReproducibilityOuput() function does not work for complex figures generated with ggpubr/cowplot
  # Please visually refer to the reference figure for checking that it matches the output
message('fig2 should match the file saved as _results/ref/fig_2_expected.rds')
message('Set read_ref_outputs to TRUE and run the following line to plot the reference file:')
if(read_ref_outputs)
  readReferenceFile("fig2")


## Refit models for fitness -------------------------------------------------------------------

# Refit models for weight and survival without the photoperiod effect (only mismatch and mismatch square)
modelSurv_fitness <- lme4::glmer(Event ~ MismTreat_noNeg + MismTreat_squared + (1 | MotherID), 
                                 family="binomial",
                                 data=cat_data_surv)

modelPupa_fitness <- lmerTest::lmer(PupaWeight ~ MismTreat_noNeg + (1 | MotherID), data=cat_data_pupa)

# Get predictions of survival for fitness curve
# Remove duplicates for each brood since all have same prediction
predSurv_fitness <- cat_data_surv[!duplicated(cat_data_surv[,c("MotherID", "MismTreat_factor")]),] 

# Predict probability of dying
predSurv_fitness$pred <- predict(modelSurv_fitness, newdata=predSurv_fitness, type="response") 
# Invert for survival probability
predSurv_fitness$survpred <- (1-predSurv_fitness$pred)

# Get predictions of weight for fitness curve
# Remove duplicates for each brood since all have same prediction
predPupa_fitness <- cat_data_pupa[!duplicated(cat_data_pupa[,c("MotherID", "MismTreat_factor")]),] 
# Predict weight
predPupa_fitness$pred <- predict(modelPupa_fitness, newdata=predPupa_fitness, type="response")

# Check prediction sample size
test_that("220 observations = 22 mothers * 10 MismTreat groups", {expect_equal(nrow(predSurv_fitness), 220)})
test_that("154 predicted weights", {expect_equal(nrow(predPupa_fitness), 154)})

# View first rows of each set of predictions
head(predSurv_fitness) # pred = probability of dying, survpred=1-pred, 
head(predPupa_fitness) # pred = predicted weight from lmer


## Fitness analysis --------------------------------------------------------------------------

# Combine weight and survival predictions
RelFit <- merge(predSurv_fitness[,c("MotherID", "MismTreat", "survpred")],
                predPupa_fitness[,c("MotherID", "MismTreat", "pred")], 
                by=c("MotherID", "MismTreat"), all=T)
colnames(RelFit)[c(3,4)] <- c("survpred", "pupwpred")

# Multiply absolute weight and survival
RelFit$RelFit_NonNul <- RelFit$survpred*RelFit$pupwpred 

# test
test_that("154 clutches with >=1 caterpillar surviving until pupation", {
  expect_equal(sum(!is.na(RelFit$pupwpred)),154)})
# for the other clutches, fitness = 0
RelFit$Fit <- ifelse(is.na(RelFit$RelFit_NonNul)==T, 0, RelFit$RelFit_NonNul)

# Fit a loess model to describe the fitness curve
loess_mod <- loess(Fit~ -1 + MismTreat,  data=RelFit) 
summary(loess_mod)

# Get predicted fitness curve, starting with index of mismatch dates
curve <- RelFit[!duplicated(RelFit[,c("MismTreat")]),] %>% select(MismTreat)

# Add predictions from loess model
curve$pred <- predict(loess_mod, newdata=curve)
curve <- arrange(curve, MismTreat)

# Calculate relative fitness compared to peak
MismTreat_FitPeak <- curve$MismTreat[curve$pred == max(curve$pred)] 
curve$rel <- curve$pred/filter(curve, MismTreat==MismTreat_FitPeak)$pred 


RelFit$rel <- RelFit$Fit/mean(filter(RelFit, MismTreat==2)$Fit)

# Get mean relative fitness for each mismatch date
RelFit_means <- Rmisc::summarySE(RelFit, measurevar="rel", groupvars=c("MismTreat"))
# Get sample size (number of caterpillars)
RelFit_means$samplesize <- aggregate(MotherID~MismTreat, data=cat_data_surv, length)$MotherID 
RelFit_means$curve <- curve$rel

# View first rows
head(RelFit_means)

# To save RelFit_means
if(save_tables) write.csv(RelFit_means, file="_results/RelFitness_rev.csv", row.names=F)
 

## Relative fitness figure ---------------------------------------------------------------------

# Render relative fitness curve
p_relfit <- ggplot(data=RelFit, aes(x=MismTreat, y=rel)) +
 # Add fitness data points
  geom_jitter(size=3, alpha=0.4, height=0, width=0.25, shape=21, fill="dodgerblue2", col="dodgerblue4")+
  # Add mean values
  geom_point(data=RelFit_means, size=5) +
  # Add error bars
  geom_errorbar(data=RelFit_means, aes(ymax = rel+se, ymin=rel-se), width=0.3) +
  # Add sample size labels
  #geom_line(data=curve, aes(y=pred), col="darkred", size=1)+
  #geom_smooth(data=curve, se=F, col="red3", size=1)+ # makes it look more like a smooth line, but otherwise exactly the same as using geom_line
  geom_text(data=RelFit_means,aes(label=samplesize, y=rel+0.12), col="black", size=5, fontface="bold")+ # number of caterpillars
  geom_hline(yintercept=1, linetype="dashed")+
  labs(y="Relative fitness", x="Mismatch with oak budburst date (days)")+
  scale_y_continuous(lim=c(0, max(RelFit$rel)), breaks=seq(0,1.6, by=0.2))+ scale_x_continuous(breaks=seq(-4,5, by=1))+ #lim=c(-0.1,1.3)
  theme(legend.position="none")+
  theme(axis.title.y=element_text(size=18, vjust=2), axis.title.x=element_text(size=18, vjust=-0.5),
        axis.text=element_text(size=16), legend.text = element_text(size=16), legend.title=element_text(size=17))

# View figure
p_relfit

# Save the figure
if(save_figures)
  ggsave(filename="_results/FitnessCurve_rev.png", plot=p_relfit, device="png", width=200, height=150, units="mm", dpi="print")
  
### Average fitness loss per day ####
#----------------------------------  #

  # 1. Hatching earlier than budburst date
fitness_loss_hatchedEarlier <- 
RelFit_means %>%
  dplyr::select(MismTreat, curve) %>%
  dplyr::filter(MismTreat <= 2) %>%
  dplyr::rename("pred_fitness" = "curve") %>%
  # What would have been the mean fitness if hatched one day later?
  mutate(lagged_fitness = lead(pred_fitness)) %>%
  mutate(fitness_loss = lagged_fitness - pred_fitness)

fitness_loss_hatchedEarlier %>% print
  # Mean value ? Should be 14%
fitness_loss_earlier <- na.omit(fitness_loss_hatchedEarlier$fitness_loss)
mean_fitness_loss_earlier <- exp(mean(log(fitness_loss_earlier))) %>% round(2)
checkReproducibilityValues(mean_fitness_loss_earlier, 0.14)
  # Max value ? Should be 32%
fitness_loss_hatchedEarlier %>% dplyr::slice(which.max(fitness_loss)) # corresponds to day -1
max_fitness_loss_earlier <- fitness_loss_hatchedEarlier$fitness_loss %>% max(na.rm = T) %>% round(2)
checkReproducibilityValues(max_fitness_loss_earlier, 0.32)

  # 2. Hatching later than budburst date
fitness_loss_hatchedLater <- 
RelFit_means %>%
  dplyr::select(MismTreat, curve) %>%
  dplyr::filter(MismTreat >= 2) %>%
  dplyr::rename("pred_fitness" = "curve") %>%
  # What would have been the mean fitness if hatched one day later?
  mutate(lagged_fitness = lag(pred_fitness)) %>%
  mutate(fitness_loss = lagged_fitness - pred_fitness)

fitness_loss_hatchedLater %>% print
  # Mean value ? Should be 13% (although reported as 6% in paper)
fitness_loss_Later <- na.omit(fitness_loss_hatchedLater$fitness_loss)
mean_fitness_loss_Later <- exp(mean(log(fitness_loss_Later))) %>% round(2)
checkReproducibilityValues(mean_fitness_loss_Later, 0.13)
  # Max value ? Should be 32%
fitness_loss_hatchedLater %>% dplyr::slice(which.max(fitness_loss)) # corresponds to day -1
max_fitness_loss_Later <- fitness_loss_hatchedLater$fitness_loss %>% max(na.rm = T) %>% round(2)
checkReproducibilityValues(max_fitness_loss_Later, 0.24)

  # To save output tables
if(save_tables) {
  write.csv(fitness_loss_hatchedEarlier, file="_results/fitness_loss_hatchedEarlier.csv")
  write.csv(fitness_loss_hatchedLater, file="_results/fitness_loss_hatchedEarlier.csv")
}
  # To save them as new references
if(save_ref_outputs) {
  write_rds(fitness_loss_hatchedEarlier, file = "_results/ref/fitness_loss_hatchedEarlier_expected.rds")
  write_rds(fitness_loss_hatchedLater, file = "_results/ref/fitness_loss_hatchedLater_expected.rds")
}
  # To check that tables match the reference files
checkReproducibilityOutput(fitness_loss_hatchedEarlier, "_results/ref/fitness_loss_hatchedEarlier_expected.rds")
checkReproducibilityOutput(fitness_loss_hatchedLater, "_results/ref/fitness_loss_hatchedLater_expected.rds")

  # To read reference files for visual comparison
if(read_ref_outputs) {
  readReferenceFile("fitness_loss_hatchedEarlier")
  readReferenceFile("fitness_loss_hatchedLater")
}


#--------------------------------------------  #
## Session info ####
#--------------------------------------------  #

if(save_session_info) 
  sessionInfo() %>% 
  capture.output(file="_src/env_CatFoodExp2021_analysis.txt")
