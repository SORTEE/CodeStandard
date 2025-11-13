# Analysis of Phenological mismatch experiment 2021 ####
# Manipulated timing of egg hatching of eggs from wild Mothers caught in 2020
# Either hatching on day of budburst (Day0), before (Day-4 to -1), or after (Day+1 to +5)
# Disentangle effects of photoperiod and food quality: photoperiod treatment (changing or constant)

# before start download the dataset 'CatFood2021_deposit.csv'
# from Dryad repository: https://doi.org/10.5061/dryad.m905qfv5p

# the dataset should be saved in the folder 1_data


# Open R project in main folder
# Restore library 
renv::restore()

# If error when downloading digest :
  # (this happens, check https://stackoverflow.com/questions/48548767/can-not-download-digest-package-in-r)
if(!require(digest))
  install.packages('digest', repos = 'http://cran.us.r-project.org')

# Setting seed for random processes
set.seed(147)

# Load packages ####
#-----------------------------------
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

#----------------------------------  #
# Load functions ####
#----------------------------------- #

pathF <- c("2_scripts/Functions/") # They are stored here
functions <- list.files(pathF)
sapply(functions, function(file) source(paste0(pathF, file))) %>% invisible

#----------------------------------------------------  #
# Checking file presence for reproducibility checks ####
#----------------------------------------------------- #

  # To verify that reference files for reproducibility checking are present
checkReferenceFilePresence()
  # To verify that outputs were already saved and stored in "_results" folder
checkOutputPresence()

#----------------------------------  #
# User configuration ####
#----------------------------------- #

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

# Create folders to store data and results ####
#-----------------------------------
sapply(c("1_data", "_results"),
       function(i) 
         if (! dir.exists(i)) dir.create(i))

# Download data from dryad repository ####
#-----------------------------------

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

# Load data ####
#-----------------------------------
catDataRaw <- read.csv("1_data/CatFood2021_deposit.csv")
test_that("raw data table has correct class and dimensions", {
  expect_s3_class(catDataRaw, "data.frame")
  expect_equal(ncol(catDataRaw), 19)
  expect_equal(nrow(catDataRaw), 976)
})
test_that("variables types are correct", {
  expect_type(catDataRaw$ExperimentName, "character")
  expect_type(catDataRaw$YearCatch, "integer")
  expect_type(catDataRaw$YearHatch, "integer")
  expect_type(catDataRaw$TubeID, "integer")
  expect_type(catDataRaw$AreaShortName, "character")
  expect_type(catDataRaw$Site, "integer")
  expect_type(catDataRaw$Tree, "integer")
  expect_type(catDataRaw$NovemberDate, "integer")
  expect_type(catDataRaw$ClutchID, "integer")
  expect_type(catDataRaw$CaterpillarID, "integer")
  expect_type(catDataRaw$Treatment, "character")
  expect_type(catDataRaw$HatchAprilDay, "integer")
  expect_type(catDataRaw$DeadAprilDay, "integer")
  expect_type(catDataRaw$PupationAprilDay, "integer")
  expect_type(catDataRaw$PupaWeight_ingrams, "double")
  expect_type(catDataRaw$AdultNovDate, "integer")
  expect_type(catDataRaw$AdultWeight_ingrams, "double")
  expect_type(catDataRaw$Sex, "character")
  expect_type(catDataRaw$Remarks, "character")
})

# Checks number of missing data consistent with article
test_that("346 pupated", {expect_equal(sum(is.na(catDataRaw$DeadAprilDay)),346)})
test_that("630 died before pupation", {
  expect_equal(sum(is.na(catDataRaw$PupationAprilDay)),630)
  expect_equal(sum(is.na(catDataRaw$PupaWeight_ingrams)),630)
})
test_that("962 died before adulthood", {
  expect_equal(sum(is.na(catDataRaw$AdultNovDate)),962)
  expect_equal(sum(is.na(catDataRaw$AdultWeight_ingrams)),962)
  expect_equal(sum(is.na(catDataRaw$Sex)),962)
})

# Check dataset
head(catDataRaw) # should print the first 6 rows and the 19 columns
summary(catDataRaw)

# Check for outliers
# Histograms should not show any outliers
hist(catDataRaw$NovemberDate)
hist(catDataRaw$PupaWeight_ingrams)
hist(catDataRaw$DeadAprilDay)
hist(catDataRaw$PupationAprilDay)
hist(catDataRaw$PupaWeight_ingrams)
hist(catDataRaw$AdultNovDate)
hist(catDataRaw$AdultWeight_ingrams)

# renaming TubeID as MotherID to match the terminology used in the Statistical section of the paper
catData <- rename(catDataRaw, MotherID = TubeID)

test_that("22 different mothers", {expect_equal(length(unique(catData$MotherID)), 22)})
test_that("15 treatment values", {expect_equal(length(unique(catData$Treatment)), 15)})
table(catData$Treatment) # photoperiod and mismatch treatment coded in one variable

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
table(catData[!duplicated(catData$MotherID), "AreaShortName"])
# should match the counts given in section 2.b Phenological mismatch experiment

#----------------------------------  #
# Fitness curve ####
#----------------------------------  #

# Survival data ####

# The following section reshapes and cleans the data to prepare it for survival analysis
catData_surv <- catData %>% mutate(PhotoTreat=gsub("(\\w+)Day.+","\\1",Treatment), MismTreat=gsub("\\w+(Day.+)","\\1",Treatment)) %>% 
  select(MotherID, Treatment, PhotoTreat, MismTreat, CaterpillarID, DeadAprilDay, PupationAprilDay) %>%
  # The pivot_longer function is used to combine the `DeadAprilDay` and `PupationAprilDay` columns into a single `TimeOfDeath` column
  # This is necessary to create a "survival" variable that indicates whether the caterpillar died or survived to pupate
  pivot_longer(cols=c(DeadAprilDay, PupationAprilDay), names_to="Info", values_to="TimeOfDeath") %>%
  filter(!is.na(TimeOfDeath)) %>%
  # The `survival` variable is created as a binary indicator for the binomial mixed model
  # It is coded as 1 for death (`DeadAprilDay`) and 0 for survival (`PupationAprilDay`)
  mutate(survival=ifelse(Info=="DeadAprilDay", 1, 0), Treatment=as.factor(Treatment), PhotoTreat=as.factor(ifelse(PhotoTreat=="Chang", "Changing", "Constant")), MismTreatf=as.factor(MismTreat), MotherID=as.factor(MotherID)) %>%
  mutate(Treatment_relevelled=factor(Treatment, levels=c("ChangDay-4", "ChangDay-3", "ChangDay-2", "ChangDay-1", "ChangDay0", "ChangDay+1", "ChangDay+2", "ChangDay+3", "ChangDay+4",
                                                         "ChangDay+5",  "ConstDay-4", "ConstDay-2", "ConstDay0", "ConstDay+2", "ConstDay+4")), 
         MismTreat_factor=factor(MismTreat, levels=c("Day-4", "Day-3", "Day-2", "Day-1", "Day0", "Day+1", "Day+2", "Day+3", "Day+4", "Day+5")),
         MismTreat=as.numeric(gsub("Day(.+)","\\1",MismTreat))) %>%
  mutate(MismTreat_noNeg=MismTreat-min(MismTreat)+1, # Transformed so that lowest value is 1, to be able to fit the squared term
         MismTreat_squared=(MismTreat-min(MismTreat)+1)^2) # squared term to add in model

test_that("survival data table has correct class and dimensions", {
  expect_s3_class(catData_surv, "data.frame")
  expect_equal(ncol(catData_surv), 12)
  expect_equal(nrow(catData_surv), 976)
})
test_that("variables types are correct", {
  expect_s3_class(catData_surv$MotherID, "factor")
  expect_s3_class(catData_surv$Treatment, "factor")
  expect_s3_class(catData_surv$PhotoTreat, "factor")
  expect_type(catData_surv$MismTreat, "double")
  expect_type(catData_surv$CaterpillarID, "integer")
  expect_type(catData_surv$Info, "character")
  expect_type(catData_surv$TimeOfEvent, "integer")
  expect_type(catData_surv$Event, "double")
  expect_s3_class(catData_surv$MismTreat_factor, "factor")
  expect_s3_class(catData_surv$Treatment_relevelled, "factor")
  expect_type(catData_surv$MismTreat_noNeg, "double")
  expect_type(catData_surv$MismTreat_squared, "double")
})

test_that("Treatment_relevelled reflects Treatment", {expect_true(all(catData_surv$Treatment_relevelled == catData_surv$Treatment))})
test_that("MismTreat_squared equals MismTreat_noNeg squared", {expect_true(all(catData_surv$MismTreat_squared == catData_surv$MismTreat_noNeg^2))})
test_that("Caterpillar ID are unique", {expect_equal(length(unique(catData_surv$CaterpillarID)), nrow(catData_surv))})

head(catData_surv) # should print the first 6 rows and the 10 columns of a tibble

#-----------------------------------
# Survival analysis ####
#-----------------------------------
levels(catData_surv$Treatment_relevelled)
levels(catData_surv$PhotoTreat)
levels(catData_surv$MismTreat_factor) 
levels(catData_surv$MotherID)
table(catData_surv$TimeOfDeath)
table(catData_surv$survival) # this variable corresponds to "survival" as defined in the paper (e.g., the response variable in the first binomial mixed-effect model)

# Visualize survival probabilities ####
surv_probs <- aggregate(survival~MismTreat + PhotoTreat + MotherID, catData_surv, sum) # per mother
surv_probs$samplesize <- aggregate(Info~MismTreat + PhotoTreat + MotherID, catData_surv, length)$Info
surv_probs$probs <- 100 - (surv_probs$survival/surv_probs$samplesize*100) # survival = death
head(surv_probs)

surv_avg <- Rmisc::summarySE(surv_probs, measurevar="probs", groupvars=c("MismTreat")) # average of two photoperiod treatments
surv_avg$samplesize <- aggregate(Info~MismTreat, catData_surv, length)$Info
surv_avg

raw_surv <- ggplot(data=surv_avg, aes(x=MismTreat, y=probs))+
  scale_colour_manual(values=c("grey27", "orangered2"))+ #"dodgerblue4"
  geom_jitter(data=surv_probs, aes(col=PhotoTreat), alpha=0.3, size=3, height=0.5, width=0.25)+
  geom_point(size=5, col="black") +
  geom_errorbar(aes(ymax = probs+se, ymin=probs-se), width=0.3, col="black") +
  geom_text(aes(label=samplesize, y=probs+8.3), col="black", size=4,fontface="bold")+ # N caterpillars in each treatment
  labs(y="Survival (%)", x="Mismatch with oak budburst date (days)")+
  scale_y_continuous(breaks=seq(0,100, by=10))+ scale_x_continuous(breaks=seq(-4, 5, by=1))+
  theme(axis.title.y=element_text(size=18, vjust=2), axis.title.x=element_text(size=18, vjust=-0.5),
        axis.text=element_text(size=16), legend.text = element_text(size=16), legend.title=element_text(size=17))
raw_surv 

if(save_figures)
  ggsave(filename="_results/Survival_raw.png", plot=raw_surv , device="png", width=200, height=150, units="mm", dpi="print")

# Fit binomial model ####
#-----------------------------------
head(catData_surv) # test if probability of survival differs between treatments

glmSurv_step1 <- lme4::glmer(survival ~ (MismTreat_noNeg + MismTreat_squared)*PhotoTreat + (1|MotherID), family=binomial, data=catData_surv,
                       na.action="na.fail", control=glmerControl(calc.derivs=F)) # helps convergence
# Check model assumptions
check_model(glmSurv_step1)

anovaSurv_step1 <- drop1(glmSurv_step1,test="Chi") %>% as.data.frame # interaction not significant; the use of Chi-square test to determine statistical significance should be explicitly mentioned in the paper
anovaSurv_step1$mod <- "glmSurv_step1"

# The interaction terms are removed here because their p-values were not significant in the `glm1` model
# Mismatch has a significant nonlinear effect on survival, while photoperiod does not. This is reflected in Figure 2a and the corresponding results section of the paper
glmSurv_step2 <- update(glmSurv_step1, ~ . -MismTreat_noNeg:PhotoTreat - MismTreat_squared:PhotoTreat) # simplify model
anovaSurv_step2 <- drop1(glmSurv_step2,test="Chi") %>% as.data.frame #no effect of PhotoTreatment, but effect of MismTreat and MismTreat^2
anovaSurv_step2$mod <- "glmSurv_step2"

# Final model ####
glmSurv_final <- glmSurv_step2
# Check model assumptions
check_model(glmSurv_final)

summary(glmSurv_final)# Estimates are log odds
glmSurv_res <- summary(glmSurv_final)$coefficients %>% as.data.frame

  # To save model outputs
if(save_tables) {
  write.csv(glm_res, file="_results/output_Surv_glmer.csv", row.names=T)
  write.csv(rbind(anova1, anova2), file="_results/anova_Surv_glmer.csv", row.names=T)
}

# Get predictions ####
glmSurv_pred <- catData_surv[!duplicated(catData_surv[,c("MotherID", "Treatment_relevelled")]),] # each replicate assigned same prediction, so remove duplicates
glmSurv_pred$pred <- predict(glmSurv_final, newdata=glmSurv_pred, type="response") # predictions are probability of dying now
glmSurv_pred$survprob <- (1-glmSurv_pred$pred)
SurvByMismTreat <- aggregate(survprob~MismTreat, data=glmSurv_pred, mean)
MismTreat_SurvPeak <- SurvByMismTreat$MismTreat[SurvByMismTreat$survprob == max(SurvByMismTreat$survprob)] # peak at Day2
glmSurv_pred$rel <- glmSurv_pred$survprob/mean(filter(glmSurv_pred, MismTreat==MismTreat_SurvPeak)$survprob) # expressive relative to peak
head(glmSurv_pred)

# Visualize predictions ####
pred_surv <- Rmisc::summarySE(glmSurv_pred, measurevar="survprob", groupvars=c("MismTreat")) # average of two photoperiod treatments
pred_surv$samplesize <- aggregate(CaterpillarID~MismTreat, data=catData_surv, length)$CaterpillarID

# Add predictions to raw data figure
p_surv <- raw_surv + #geom_line(data=pred, aes(y=survprob*100)) +
  geom_smooth(data=pred_surv, aes(y=survprob*100), se=F, col="red3")
p_surv

  # To save the figure
if(save_figures)
  ggsave(filename="_results/Survival_wpred_rev.png", plot=p_surv, device="png", width=200, height=150, units="mm", dpi="print")

  # To save it as the reference file for reproducibility tests
if(save_ref_outputs)
  write_rds(p_surv, "_results/ref/p_surv_expected.rds")

  # To check correspondence with saved figure (reference)
checkReproducibilityOutput(obtained = p_surv, 
                           ref_path = "_results/ref/p_surv_expected.rds", # the expected figure saved as a .RDS
                           ref_vis = "_resultsSurvival_wpred_rev.png", # the expected figure saved as a .PNG
                           print = F)

# To read the reference file for visual comparison
if(read_ref_outputs) readReferenceFile("p_surv")


#-----------------------------------
# Pupation weight analysis ####
#-----------------------------------

# This section prepares the data for pupation weight analysis by creating new variables for photoperiod and mismatch treatment,
# and converting pupation weight from grams to milligrams for better readability
catData_pupa <- catData %>% mutate(PhotoTreat=gsub("(\\w+)Day.+","\\1",Treatment), MismTreat=gsub("\\w+(Day.+)","\\1",Treatment), PupaWeight=PupaWeight_ingrams*1000) %>%
  select(ExperimentName, MotherID, Treatment, PhotoTreat, MismTreat, CaterpillarID, PupationAprilDay, PupaWeight) %>%
  filter(!is.na(PupationAprilDay)) %>%
  mutate(Treatment=as.factor(Treatment), PhotoTreat=as.factor(ifelse(PhotoTreat=="Chang", "Changing", "Constant")), MismTreat_factor=as.factor(MismTreat), MotherID=as.factor(MotherID)) %>%
  mutate(Treatment_relevelled=factor(Treatment, levels=c("ChangDay-4", "ChangDay-3", "ChangDay-2", "ChangDay-1", "ChangDay0", "ChangDay+1", "ChangDay+2", "ChangDay+3", "ChangDay+4",
                                                         "ChangDay+5",  "ConstDay-4", "ConstDay-2", "ConstDay0", "ConstDay+2", "ConstDay+4")), 
         MismTreat_factor=factor(MismTreat, levels=c("Day-4", "Day-3", "Day-2", "Day-1", "Day0", "Day+1", "Day+2", "Day+3", "Day+4", "Day+5")),
         MismTreat=as.numeric(gsub("Day(.+)","\\1",MismTreat))) %>%
  mutate(MismTreat_noNeg=MismTreat-min(MismTreat)+1, # Transformed so that lowest value is 1, to be able to fit the squared term
         MismTreat_squared=(MismTreat-min(MismTreat)+1)^2) # squared term to add in model

test_that("pupa data table has correct class and dimensions", {
  expect_s3_class(catData_pupa, "data.frame")
  expect_equal(ncol(catData_pupa), 12)
  expect_equal(nrow(catData_pupa), 346) # 346 individuals survived until pupation
})
test_that("variables types are correct", {
  expect_type(catData_pupa$ExperimentName, "character")
  expect_s3_class(catData_pupa$MotherID, "factor")
  expect_s3_class(catData_pupa$Treatment, "factor")
  expect_s3_class(catData_pupa$PhotoTreat, "factor")
  expect_type(catData_pupa$MismTreat, "double")
  expect_type(catData_pupa$CaterpillarID, "integer")
  expect_type(catData_pupa$PupationAprilDay, "integer")
  expect_type(catData_pupa$PupaWeight, "double")
  expect_s3_class(catData_pupa$MismTreat_factor, "factor")
  expect_s3_class(catData_pupa$Treatment_relevelled, "factor")
  expect_type(catData_pupa$MismTreat_noNeg, "double")
  expect_type(catData_pupa$MismTreat_squared, "double")
})

test_that("Treatment_relevelled reflects Treatment", {expect_true(all(catData_pupa$Treatment_relevelled == catData_pupa$Treatment))})
test_that("MismTreat_squared equals MismTreat_noNeg squared", {expect_true(all(catData_pupa$MismTreat_squared == catData_pupa$MismTreat_noNeg^2))})
test_that("Caterpillar ID are unique", {expect_equal(length(unique(catData_pupa$CaterpillarID)), nrow(catData_pupa))})

head(catData_pupa)

# Overall survival probability
nrow(catData_pupa)/nrow(catData)*100 # ~35%

# Visualize ####
weight <- Rmisc::summarySE(catData_pupa, measurevar="PupaWeight", groupvars=c("MismTreat", "PhotoTreat"))
# The warning message occurs because at Mismatch = -4 sample size is N = 1 for both treatments
# and standard deviations cannot be computed
weight$pos <- ifelse(is.na(weight$se)==T, 0, weight$se) # position of sample size labels
weight

  # Saving reference weight file
if(save_ref_outputs) write_rds(weight, "_results/ref/weight_expected.rds")
  # Reproducibility checking
checkReproducibilityOutput(weight, "_results/ref/weight_expected.rds")
  # To read the reference file for visual comparison
if(read_ref_outputs) readReferenceFile("weight")


raw_weight <- ggplot(data=weight, aes(x=MismTreat, y=PupaWeight, col=PhotoTreat, fill=PhotoTreat))+
  scale_colour_manual(values=c("grey27", "orangered2"))+ #"dodgerblue4"
  scale_fill_manual(values=c("grey27", "orangered2"))+
  geom_jitter(data=catData_pupa, aes(col=PhotoTreat), alpha=0.3, size=3, height=0, width=0.25)+ #alpha=0.3, size=2, height=0, width=0.25
  geom_errorbar(data=filter(weight, PhotoTreat=="Changing"), aes(ymax = PupaWeight+se, ymin=PupaWeight-se), width=0.3, col="black") +
  geom_errorbar(data=filter(weight, PhotoTreat=="Constant"), aes(ymax = PupaWeight+se, ymin=PupaWeight-se), width=0.3, col="orangered4") +
  geom_point(size=5, shape=21, col="black")+
  #geom_text(data=filter(weight, PhotoTreat=="Changing"),aes(label=N, y=PupaWeight-pos-2.3), col="black", size=4, fontface="bold")+
  #geom_text(data=filter(weight, PhotoTreat=="Constant"),aes(label=N, y=PupaWeight+pos+2.3), col="black", size=4, fontface="bold")+
  labs(y="Weight at pupation (mg)", x="Mismatch with oak budburst date (days)")+
  scale_y_continuous(breaks=seq(15,75, by=10))+ scale_x_continuous(breaks=seq(-4, 5, by=1))+
  theme(axis.title.y=element_text(size=18, vjust=2), axis.title.x=element_text(size=18, vjust=-0.5),
        axis.text=element_text(size=16), legend.text = element_text(size=16), legend.title=element_text(size=17))
raw_weight  

# To save the figure
if(save_figures)
  ggsave(filename="_results/PupWeight_raw.png", plot=raw_weight , device="png", width=200, height=150, units="mm", dpi="print")

# Fit linear mixed model ####
#-----------------------------------
lmPupa_step1 <- lmerTest::lmer(PupaWeight ~ (MismTreat_noNeg + MismTreat_squared)*PhotoTreat + (1|MotherID), data=catData_pupa)
# Check model assumptions
check_model(lmPupa_step1)
# Line 20 is a clear outlier.

anovaPupa_step1 <- anova(lmPupa_step1) %>% as.data.frame() # interaction not significant
anovaPupa_step1$mod <- "lmPupa_step1"

# The interaction terms are removed here because they were not significant in the `lm1` model
lmPupa_step2 <- update(lmPupa_step1, ~ . - MismTreat_noNeg:PhotoTreat - MismTreat_squared:PhotoTreat) # simplify model
anovaPupa_step2 <- anova(lmPupa_step2) %>% as.data.frame() # Squared mismatch not significant
anovaPupa_step2$mod <- "lmPupa_step2"

# The squared mismatch term (`MismTreat2`) is removed here because it was not significant in the `lm2` model
# Pupation weight is linearly affected by mismatch and has a significant photoperiod effect, as stated in the results section of the paper and shown in Figure 2b
lmPupa_step3 <- update(lmPupa_step2, ~ . - MismTreat_squared) # simplify model
anovaPupa_step3 <- anova(lmPupa_step3) %>% as.data.frame() # PhotoTreat and MismTreat significant
anovaPupa_step3$mod <- "lmPupa_step3"

# Still there if exclude first time point with low sample size?
# Check to see if the model's results change when the `MismTreat == -4` data point is removed,
# as it has a very low sample size. The results are still significant, indicating the findings are robust
lmPupa_step3_excludeOutlier <- lmerTest::lmer(PupaWeight ~ -1 + MismTreat_noNeg + PhotoTreat + (1|MotherID), data=filter(catData_pupa, MismTreat!=-4))
anova(lmPupa_step3_excludeOutlier) # yes
check_model(lmPupa_step3_excludeOutlier)

# Final model ####
lmPupa_final <- lmPupa_step3
# Check model assumptions
check_model(lmPupa_final)

summary(lmPupa_final)
lmPupa_res <- summary(lmPupa_final)$coefficients %>% as.data.frame

# To save model outputs
if(save_tables) {
  write.csv(lm_res, file="_results/output_PupaWeight_lmer.csv", row.names=T)
  write.csv(rbind(anova1, anova2, anova3), file="_results/anova_PupaWeight_lmer.csv", row.names=T)
}

# Get predictions ####
lmPupa_pred <- catData_pupa[!duplicated(catData_pupa[,c("MotherID", "Treatment_relevelled")]),] # each replicate assigned same prediction, so remove duplicates
lmPupa_pred$pred <- predict(lmPupa_final, newdata=lmPupa_pred, type="response")
head(lmPupa_pred)

# Visualize predictions ####
pred_pupa <- Rmisc::summarySE(lmPupa_pred, measurevar="pred", groupvars=c("MismTreat", "PhotoTreat")) # significant effect of photoperiod, so show separate means
## The warning message occurs because at Mismatch = -4 sample size is N = 1 for both treatments
# and standard deviations cannot be computed
pred_pupa$samplesize <- weight$N
pred_pupa$pos <- ifelse(is.na(pred_pupa$se)==T, 0, pred_pupa$se) # position of sample size labels

# add predictions to raw data figure
p_weight <- raw_weight + #geom_line(data=pred_pupa, aes(y=pred)) +
  geom_smooth(data=pred_pupa, aes(y=pred, col=PhotoTreat), se=F, method=lm)+
  geom_text(data=filter(weight, PhotoTreat=="Changing"),aes(label=N, y=PupaWeight-pos-1.5), col="black", size=4, fontface="bold")+
  geom_text(data=filter(weight, PhotoTreat=="Constant"),aes(label=N, y=PupaWeight+pos+2.3), col="black", size=4, fontface="bold")
p_weight

# To save the figure
if(save_figures)
  ggsave(filename="_results/PupWeight_wpred_rev.png", plot=p_weight, device="png", width=200, height=150, units="mm", dpi="print")

## Making figure 2 ####
#--------------------------------------------  #

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


## Get fitness curve ####
#--------------------------------------------  #

# Don't care about PhotoTreat effect, drop from models
glm_fit <- glmer(Event ~ MismTreat1 + MismTreat2 + (1 | MotherID), family="binomial", data=d_surv)
lm_fit <- lmer(PupaWeight ~ MismTreat1 + (1 | MotherID), data=d_pupa)

### Get predictions to use for curve ####
glm.fit <- d_surv[!duplicated(d_surv[,c("MotherID", "MismTreatf")]),] # each replicate assigned same prediction, so remove duplicates
glm.fit$pred <- predict(glm_fit, newdata=glm.fit, type="response") # predictions are probability of dying now
glm.fit$survpred <- (1-glm.fit$pred)

lm.fit <- d_pupa[!duplicated(d_pupa[,c("MotherID", "MismTreatf")]),] # each replicate assigned same prediction, so remove duplicates
lm.fit$pred <- predict(lm_fit, newdata=lm.fit, type="response")

#--------------------------------------------
# Get fitness curve ####
#--------------------------------------------

# Don't care about PhotoTreat effect, drop from models ####
modelSurv_fitness <- lme4::glmer(Event ~ MismTreat_noNeg + MismTreat_squared + (1 | MotherID), family="binomial", data=catData_surv)
modelPupa_fitness <- lmerTest::lmer(PupaWeight ~ MismTreat_noNeg + (1 | MotherID), data=catData_pupa)

# Get predictions to use for curve ####
predSurv_fitness <- catData_surv[!duplicated(catData_surv[,c("MotherID", "MismTreat_factor")]),] # each replicate assigned same prediction, so remove duplicates
predSurv_fitness$pred <- predict(modelSurv_fitness, newdata=predSurv_fitness, type="response") # predictions are probability of dying now
predSurv_fitness$survpred <- (1-predSurv_fitness$pred)

predPupa_fitness <- catData_pupa[!duplicated(catData_pupa[,c("MotherID", "MismTreat_factor")]),] # each replicate assigned same prediction, so remove duplicates
predPupa_fitness$pred <- predict(modelPupa_fitness, newdata=predPupa_fitness, type="response")

test_that("220 observations = 22 mothers * 10 MismTreat groups", {expect_equal(nrow(predSurv_fitness), 220)})
head(predSurv_fitness) # pred = probability of dying, survpred=1-pred, 
test_that("154 predicted weights", {expect_equal(nrow(predPupa_fitness), 154)})
head(predPupa_fitness) # pred=predicted weight from lmer


# Fit curve to absolute fitness ####
#-----------------------------------
RelFit <- merge(predSurv_fitness[,c("MotherID", "MismTreat", "survpred")], predPupa_fitness[,c("MotherID", "MismTreat", "pred")], by=c("MotherID", "MismTreat"), all=T)
colnames(RelFit)[c(3,4)] <- c("survpred", "pupwpred")
RelFit$RelFit_NonNul <- RelFit$survpred*RelFit$pupwpred # multiply absolute values
test_that("154 clutches with >=1 caterpillar surviving until pupation", {
  expect_equal(sum(!is.na(RelFit$pupwpred)),154)})
# for the other clutches, fitness = 0
RelFit$Fit <- ifelse(is.na(RelFit$RelFit_NonNul)==T, 0, RelFit$RelFit_NonNul)

# loess model to describe the curve ####
loess_mod <- loess(Fit~ -1 + MismTreat,  data=RelFit) 
summary(loess_mod)

curve <- RelFit[!duplicated(RelFit[,c("MismTreat")]),] %>% select(MismTreat)
curve$pred <- predict(loess_mod, newdata=curve)
curve <- arrange(curve, MismTreat)
MismTreat_FitPeak <- curve$MismTreat[curve$pred == max(curve$pred)] # peak at Day2
curve$rel <- curve$pred/filter(curve, MismTreat==MismTreat_FitPeak)$pred # expressive relative to peak

RelFit$rel <- RelFit$Fit/mean(filter(RelFit, MismTreat==2)$Fit)

RelFit_means <- Rmisc::summarySE(RelFit, measurevar="rel", groupvars=c("MismTreat"))
#RelFit_means$samplesize <- aggregate(MotherID~MismTreat, data=catData_pupa, length)$MotherID # number of caterpillars curve is based on pupa data
RelFit_means$samplesize <- aggregate(MotherID~MismTreat, data=catData_surv, length)$MotherID # number of caterpillars curve is based on = all
RelFit_means$curve <- curve$rel
head(RelFit_means)

  # To save RelFit_means
if(save_tables) write.csv(RelFit_means, file="_results/RelFitness_rev.csv", row.names=F)
  # To save it as a new reference
if(save_ref_outputs) write_rds(RelFit_means, file = "_results/ref/RelFit_means_expected.rds")
  # To check that the table matches the reference file
checkReproducibilityOutput(RelFit_means, "_results/ref/RelFit_means_expected.rds")
  # To read the reference file for visual comparison
if(read_ref_outputs) readReferenceFile("RelFit_means")

### Visualize predictions ####
p_relfit <- ggplot(data=RelFit, aes(x=MismTreat, y=rel)) +
  geom_jitter(size=3, alpha=0.4, height=0, width=0.25, shape=21, fill="dodgerblue2", col="dodgerblue4")+
  geom_point(data=RelFit_means, size=5) +
  geom_errorbar(data=RelFit_means, aes(ymax = rel+se, ymin=rel-se), width=0.3) +
  #geom_line(data=curve, aes(y=pred), col="darkred", size=1)+
  #geom_smooth(data=curve, se=F, col="red3", size=1)+ # makes it look more like a smooth line, but otherwise exactly the same as using geom_line
  geom_text(data=RelFit_means,aes(label=samplesize, y=rel+0.12), col="black", size=5, fontface="bold")+ # number of caterpillars
  geom_hline(yintercept=1, linetype="dashed")+
  labs(y="Relative fitness", x="Mismatch with oak budburst date (days)")+
  scale_y_continuous(lim=c(0, max(RelFit$rel)), breaks=seq(0,1.6, by=0.2))+ scale_x_continuous(breaks=seq(-4,5, by=1))+ #lim=c(-0.1,1.3)
  theme(legend.position="none")+
  theme(axis.title.y=element_text(size=18, vjust=2), axis.title.x=element_text(size=18, vjust=-0.5),
        axis.text=element_text(size=16), legend.text = element_text(size=16), legend.title=element_text(size=17))
p_relfit

# To save the figure
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
