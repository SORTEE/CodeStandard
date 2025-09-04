## Analysis of Phenological mismatch experiment 2021 
#
# In this study, caterpillar eggs were taken from wild mothers caught in 2020. Timing of egg hatching
# was manipulated, with eggs either hatching on the day of budburst (Day0), before (Day-4 to -1),
# or after (Day+1 to +5). The photoperiod was also manipulated, with either a constant or changing
# photoperiod.
#
# To run this down, download the dataset 'CatFood2021_deposit.csv' from Dryad repository: 
# https://doi.org/10.5061/dryad.m905qfv5p

# The dataset should be saved in the folder Data/
# Open the R project in the main folder of this repository.


# Setup ---------------------------------------------------------------------------------------
# This section loads the required packages, reads in the data required for the analysis, and
# provides some simple summaries of the data structure.

## Load R environment --------------------------------------------------------------------------
# This restores the versions of packages used in the original analysis.
renv::restore()


## Load packages -------------------------------------------------------------------------------
library(tidyverse)
library(cowplot)
library(lme4)
library(lmerTest)
library(Rmisc)


## Load data -----------------------------------------------------------------------------------
# Load data for analysis. This must be downloaded from the Dryad repository prior to running
cat_food_data <- read.csv("Data/CatFood2021_deposit.csv")

## View first columns
head(cat_food_data)

## Rename TubeID to 'MotherID' to match with the paper's terminology
cat_food_data <- dplyr::rename(cat_food_data, MotherID = TubeID)


## Data summary -------------------------------------------------------------------------------
# Quick checks of the data's structure

# Check the number of unique mothers (should be 22)
length(unique(cat_food_data$MotherID)) 

# View samples: each treatment includes the photoperiod (Constant or Changing) and the mismatch date
table(cat_food_data$Treatment) 

# View number of mother per study area
table(cat_food_data[!duplicated(cat_food_data$MotherID), "AreaShortName"])


# Fitness analysis ----------------------------------------------------------------------------
# This section addresses research question 1: What are the fitness consequences of day-to-day 
# timing (a)synchrony with budburst?


## Survival data preparation ------------------------------------------------------------------

survival_data <- cat_food_data |> 
  # Separate the two components of treatment (Photoperiod and mismatch period)
  mutate(PhotoTreat = gsub("(\\w+)Day.+","\\1", Treatment), 
         MismTreat = gsub("\\w+(Day.+)","\\1", Treatment)) |> 
  # Remove extraneous columns
  select(MotherID, Treatment, PhotoTreat, MismTreat, 
         CaterpillarID, DeadAprilDay, PupationAprilDay) |>
  # Move the death and pupation dates into long format
  pivot_longer(cols = c(DeadAprilDay, PupationAprilDay), 
               names_to = "Info", values_to = "TimeOfEvent") |>
  filter(!is.na(TimeOfEvent)) |>
  # Indicate rows corresponding to date of death in the 'Event' column
  mutate(Event = ifelse(Info == "DeadAprilDay", 1, 0)) |>
  # Coerce columns to factors 
  mutate(Treatment = as.factor(Treatment), 
         PhotoTreat = as.factor(ifelse(PhotoTreat == "Chang", "Changing", "Constant")), 
         MismTreatf = as.factor(MismTreat), 
         MotherID = as.factor(MotherID)) |>
  # Order factor levels, adding numeric and factor versions of mismatch treatment
  mutate(Treatment = factor(Treatment, levels = c("ChangDay-4", "ChangDay-3", "ChangDay-2", 
                                                  "ChangDay-1", "ChangDay0", "ChangDay+1",
                                                  "ChangDay+2", "ChangDay+3", "ChangDay+4",
                                                  "ChangDay+5",  "ConstDay-4", "ConstDay-2", 
                                                  "ConstDay0", "ConstDay+2", "ConstDay+4")), 
         MismTreatf = factor(MismTreat, levels = c("Day-4", "Day-3", "Day-2", "Day-1", "Day0",
                                                   "Day+1", "Day+2", "Day+3", "Day+4", "Day+5")),
         MismTreat = as.numeric(gsub("Day(.+)", "\\1", MismTreat))) |>
  # Add 5 to ensure all mismatch dates are positive for modelling, and add a column with a quadratic term
  mutate(MismTreat1 = MismTreat + 5,
         MismTreat2 = (MismTreat + 5)^2)

# View first rows of processed data
head(survival_data)

# Look at structure
str(survival_data)

# View squared mismatch dates (note all are positive)
table(survival_data$MismTreat2)

# Check the number of unique caterpillars (should be 976)
length(unique(survival_data$CaterpillarID))

# View levels of each variable to be used for modelling
levels(survival_data$Treatment)
levels(survival_data$PhotoTreat)
levels(survival_data$MismTreatf)
levels(survival_data$MotherID)

# 'TimeOfEvent' is date of either death or pupation
table(survival_data$TimeOfEvent)

# 'Event' is the response variable (e.g., whether the caterpillar died or not) 
table(survival_data$Event)


## Survival analysis --------------------------------------------------------------------------

# Get the number of deaths in each brood
survival_probs <- aggregate(Event~MismTreat + PhotoTreat + MotherID, survival_data, sum) 

# Add the number of individuals in each brood
survival_probs$samplesize <- aggregate(Info~MismTreat + PhotoTreat + MotherID, survival_data, length)$Info

# Calculate the proportion of caterpillars surviving
survival_probs$probs <- 100 - (survival_probs$Event/survival_probs$samplesize*100)

# View first few rows
head(survival_probs)

# Take the average survival rate for each mismatch period (averaged between both photoperiod treatments)
survival_avg <- Rmisc::summarySE(survival_probs, measurevar = "probs", groupvars = c("MismTreat")) 

# Add sample size
survival_avg$samplesize <- aggregate(Info~MismTreat, survival_data, length)$Info

# View survival rates for each mismatch period
survival_avg


## Survival figure ----------------------------------------------------------------------------

# Render figure of survival rate by mismatch date
raw_survival_plot <- ggplot(data = survival_avg, 
                            aes(x = MismTreat, y = probs)) +
  # Add points, errorbars, and labels for the mean survival by date
  geom_point(size = 5, colour = "black") +
  geom_errorbar(aes(ymax = probs+se, ymin = probs-se),
                width = 0.3, colour = "black") +
  geom_text(aes(label = samplesize, y = probs+8.3), 
            colour = "black", size = 4, fontface = "bold")+ # N caterpillars in each treatment
  # Add transparent points for the survival rates split by photoperiod
  geom_jitter(data = survival_probs, aes(color = PhotoTreat), 
              alpha = 0.3, size = 3, height = 0.5, width = 0.25)+
  scale_colour_manual(values = c("grey27", "orangered2")) + #"dodgerblue4"
  scale_y_continuous(breaks = seq(0, 100, by = 10)) + 
  scale_x_continuous(breaks = seq(-4, 5, by = 1))+
  labs(y = "Survival (%)", x = "Mismatch with oak budburst date (days)")+
  theme(axis.title.y = element_text(size = 18, vjust = 2), 
        axis.title.x = element_text(size = 18, vjust = -0.5),
        axis.text = element_text(size = 16),
        legend.text = element_text(size = 16), 
        legend.title = element_text(size = 17)) +
  theme_cowplot()

# View figure
raw_survival_plot

# Save to outputs
ggsave(filename = "Outputs/Survival_raw.png",
       plot = raw_survival_plot, device = "png",
       width = 200, height = 150, units = "mm", 
       dpi = "print")


## Fit binomial survival model -----------------------------------------------------------------

# Fit generalised linear mixed model for probability of death, with a random effect for brood,
# fixed effects for mismatch treatment, mismatched treatment squared, and photoperiod, and an
# interaction between mismatch and photoperiod treatments.
glm_survival_full <- lme4::glmer(Event ~ (MismTreat1 + MismTreat2)*PhotoTreat + (1|MotherID), 
                                 data = survival_data,
                                 family = binomial, 
                                 na.action = "na.fail", 
                                 control = glmerControl(calc.derivs = FALSE)) 

# Use ANOVA to identify non-significant terms (In this case, both interactions)
anova_survival_full <- drop1(glm_survival_full, test = "Chi") |>
  as.data.frame() 

# Label ANOVA with model name
anova_survival_full$mod <- "glm_survival_full"

# Refit the model without the interactions 
glm_survival_no_interact <- update(glm_survival_full,
                                   ~ . -MismTreat1:PhotoTreat - MismTreat2:PhotoTreat) 

# Test significance of updated model with ANOVA 
# (Photoperiod not significant, but both mismatch treatment covariates are)
anova_survival_no_interact <- drop1(glm_survival_no_interact, test="Chi") |> 
  as.data.frame()

# Label updated model
anova_survival_no_interact$mod <- "glm_survival_no_interact"

# Use the model without interactions as the final model
glm_final <- glm_survival_no_interact

# Summarise model estimates (given as log odds)
summary(glm_final)

# Extract estimated coefficients as dataframe
glm_survival_results <- summary(glm_final)$coefficients |> 
  as.data.frame()

# Save estimates
write.csv(glm_survival_results,
          file = "Outputs/Output_Survival_glmer.csv", 
          row.names = TRUE)
# Save anova outputs
write.csv(rbind(anova_survival_full, anova_survival_no_interact),
          file = "Outputs/Output_Survival_anova.csv", 
          row.names = TRUE)


## Predict survival ---------------------------------------------------------------------------

# Remove duplicate replicates
predict_survival <- survival_data[!duplicated(survival_data[,c("MotherID", "Treatment")]),] 

# Predict the probability of death
predict_survival$ProbDeath <- predict(glm_final, newdata = predict_survival, type="response")

# Invert to get probability of survival
predict_survival$ProbSurvival <- (1-predict_survival$ProbDeath)

# View predicted survival probability by day (peaks at Day 2)
aggregate(ProbSurvival ~ MismTreat, data = predict_survival, mean)

# Calculate survival probability relative to peak
predict_survival$RelativeSurvival <- predict_survival$ProbSurvival/mean(filter(predict_survival, MismTreat == 1)$ProbSurvival) 

# View first rows of dataset
head(predict_survival)


## Predicted survival figure ------------------------------------------------------------------


# Visualize predictions 
# Get predicted daily survival, averaged across both photoperiods
average_predict_survival <- Rmisc::summarySE(predict_survival, measurevar = "ProbSurvival", groupvars = c("MismTreat"))
average_predict_survival$SampleSize <- aggregate(CaterpillarID ~ MismTreat, 
                                                 data = survival_data, length)$CaterpillarID

# Add predictions to raw data figure
predicted_survival_plot <- raw_survival_plot + #geom_line(data=pred, aes(y=survprob*100)) +
  geom_smooth(data = average_predict_survival, aes(y = ProbSurvival*100), se = FALSE, colour = "red3")

# View plot
predicted_survival_plot

# Save output
ggsave(filename = "Outputs/Survival_predicted.png", 
       plot = predicted_survival_plot, 
       device = "png", dpi = "print", 
       width = 200, height = 150, units = "mm")

rm(anova1, anova2, glm_res, glm1, glm2, pred, surv_probs, surv_avg, raw_surv) #cleanup


# Pupation weight analysis --------------------------------------------------------------------
# This section analyses the impact of mismatch date and photoperiod on weight at pupation. 
# GLMs are fit to identify significant covariates, and plots of the relationships are rendered.


## Pupation data preparation ------------------------------------------------------------------

# View first few rows of data again
head(cat_food_data)

# Manipulate into long format suitable for modelling
pupa_data <- cat_food_data |>
  # Split treatment into its components (mismatch date and photoperiod)
  mutate(PhotoTreat = gsub("(\\w+)Day.+", "\\1", Treatment),
         MismTreat = gsub("\\w+(Day.+)", "\\1", Treatment),
         PupaWeight = PupaWeight_ingrams*1000) |>
  # Select only meaningful columns
  select(ExperimentName, MotherID, Treatment, PhotoTreat, MismTreat, 
         CaterpillarID, PupationAprilDay, PupaWeight) |>
  # Remove caterpillars that did not pupate
  filter(!is.na(PupationAprilDay)) |>
  # Convert variables into factors for modelling
  mutate(Treatment = as.factor(Treatment), 
         PhotoTreat = as.factor(ifelse(PhotoTreat == "Chang", "Changing", "Constant")),
         MismTreatf = as.factor(MismTreat), 
         MotherID = as.factor(MotherID)) |>
  # Set factor levels for treatments in appropriate order and get numeric version of mismatch date
  mutate(Treatment = factor(Treatment, levels = c("ChangDay-4", "ChangDay-3", "ChangDay-2", 
                                                  "ChangDay-1", "ChangDay0", "ChangDay+1",
                                                  "ChangDay+2", "ChangDay+3", "ChangDay+4",
                                                  "ChangDay+5",  "ConstDay-4", "ConstDay-2", 
                                                  "ConstDay0", "ConstDay+2", "ConstDay+4")), 
         MismTreatf = factor(MismTreat, levels = c("Day-4", "Day-3", "Day-2", "Day-1", 
                                                   "Day0", "Day+1", "Day+2", "Day+3",
                                                   "Day+4", "Day+5")),
         MismTreat = as.numeric(gsub("Day(.+)", "\\1" , MismTreat))) |>
  # Add 5 to mismatch date to ensure all are positive and add squared term for modelling
  mutate(MismTreat1 = MismTreat + 5, 
         MismTreat2 = (MismTreat + 5)^2)


## Pupation analysis --------------------------------------------------------------------------

# View first rows of processed data
head(pupa_data) # 346 individuals survived until pupation

# Check number of individuals that survived to pupation (346)
nrow(pupa_data)

# Check percentage that pupated (35.45)
nrow(pupa_data)/nrow(cat_food_data)*100



## Pupa weight figure -------------------------------------------------------------------------

# Summarise mean weight for each treatment (some SEs not calculated as n=1 for some treatments)
pupa_weight <- Rmisc::summarySE(pupa_data, 
                                measurevar = "PupaWeight", 
                                groupvars = c("MismTreat", "PhotoTreat"))

# Set position of labels for each pupa weight 
pupa_weight$Position <- ifelse(is.na(pupa_weight$se) == TRUE, 0, pupa_weight$se)

# View summary
pupa_weight

# Render figure of pupation weight by treatment
raw_weight_figure <- ggplot(data = pupa_weight,
                            aes(x = MismTreat, y = PupaWeight, 
                                colour = PhotoTreat, fill = PhotoTreat)) +
  # Add mean value for each treatment
  geom_point(size = 5, shape = 21, colour = "black") +
  # Add error bars for each photoperiod group
  geom_errorbar(data = filter(pupa_weight, PhotoTreat == "Changing"),
                aes(ymax = PupaWeight + se, ymin = PupaWeight - se), 
                width = 0.3, colour = "black") +
  geom_errorbar(data = filter(pupa_weight, PhotoTreat == "Constant"),
                aes(ymax = PupaWeight + se, ymin = PupaWeight - se), 
                width = 0.3, colour = "orangered4") +
  # Add individual data points
  geom_jitter(data = pupa_data, aes(colour = PhotoTreat), 
              alpha = 0.3, size = 3, height = 0, width = 0.25) +
  # Add labels for sample size
  geom_text(data = filter(pupa_weight, PhotoTreat == "Changing"),
            aes(label = N, y = PupaWeight - Position - 2.3),
            colour = "black", size = 4, fontface = "bold") +
  geom_text(data = filter(pupa_weight, PhotoTreat == "Constant"),
            aes(label = N, y = PupaWeight + Position + 2.3), 
            colour = "black", size = 4, fontface = "bold") +
  scale_colour_manual(values = c("grey27", "orangered2")) +
  scale_fill_manual(values = c("grey27", "orangered2")) +
  labs(y = "Weight at pupation (mg)", x = "Mismatch with oak budburst date (days)") +
  scale_y_continuous(breaks = seq(15, 75, by = 10)) + 
  scale_x_continuous(breaks = seq(-4, 5, by = 1)) +
  theme(axis.title.y = element_text(size = 18, vjust = 2),
        axis.title.x = element_text(size = 18, vjust = -0.5),
        axis.text = element_text(size = 16),
        legend.text = element_text(size = 16),
        legend.title = element_text(size = 17)) +
  theme_cowplot()

# View figure
raw_weight_figure

# Save output
ggsave(filename = "Outputs/PupaWeight_raw.png", 
       plot = raw_weight_figure, 
       device = "png", dpi="print",
       width = 200, height = 150, units = "mm")


## Fit linear mixed model for weight ---------------------------------------------------------

# Fit full linear mixed model with fixed effects for mismatch date, mismatch date squared, and photoperiod,
# interactions between mismatch date and photoperiod, and a random effect for brood
lm_weight_full <- lmer(PupaWeight ~ (MismTreat1 + MismTreat2)*PhotoTreat + (1|MotherID), data = pupa_data)

# Check significance of covariates (interactions not significant)
anova_weight_full <- anova(lm_weight_full) |> 
  as.data.frame()

# Label anova
anova_weight_full$mod <- "lm_weight_full"

# Refit without interactions
lm_weight_no_interact <- update(lm_weight_full, ~ . - MismTreat1:PhotoTreat - MismTreat2:PhotoTreat) 

# Check significance again (squared mismatch not significant)
anova_weight_no_interact <- anova(lm_weight_no_interact) |>
  as.data.frame() 

# Label anova
anova_weight_no_interact$mod <- "lm_weight_no_interact"

# Refit without squared mismatch
lm_weight_no_squared <- update(lm_weight_no_interact, ~ . - MismTreat2)

# Check significance again (both photoperiod and mismatch significant)
anova_weight_no_squared <- anova(lm_weight_no_squared) |> 
  as.data.frame() 
anova_weight_no_squared$mod <- "lm_weight_no_squared"

# Refit without first period with low sample size to check if it's still significant
lm_weight_without_first <- lmer(PupaWeight ~ -1 + MismTreat1 + PhotoTreat + (1|MotherID),
                                data = filter(pupa_data, MismTreat != -4))

# Check significance (Still good without first timestep)
anova(lm_weight_without_first)


# Use the version with the first time-step included for the final model
lm_weight_final <- lm_weight_no_squared

# View model summary
summary(lm_weight_final)

# Get results
lm_weight_results <- summary(lm_weight_final)$coefficients |>
  as.data.frame()

# Check for equal variance (okay)
plot(lm_weight_final)

# Check residuals normally distributed (okay)
qqnorm(resid(lm_weight_final)) 
qqline(resid(lm_weight_final))

# Save coefficient estimates
write.csv(lm_weight_results,
          file = "Outputs/Output_PupaWeight_lmer.csv", 
          row.names = TRUE)
write.csv(rbind(anova_weight_full, anova_weight_no_interact, anova_weight_no_squared), 
          file = "Outputs/Output_PupaWeight_anova.csv", 
          row.names = TRUE)


## Predict weight -----------------------------------------------------------------------------

# Remove duplicates from same brood, since all will have the same prediction
predict_weight <- pupa_data[!duplicated(pupa_data[, c("MotherID", "Treatment")]), ] 

# Predict pupation weight for each 
predict_weight$PredWeight <- predict(lm_weight_final, newdata = predict_weight, type = "response")

# View first rows
head(predict_weight)


## Predicted weight figure --------------------------------------------------------------------
# Get mean prediction and SEs for each treatment - some have NA standard errors due to sample size
predicted_weight_average <- Rmisc::summarySE(predict_weight, 
                                             measurevar = "PredWeight",
                                             groupvars = c("MismTreat", "PhotoTreat"))


# Add predictions to raw weight figure
predicted_weight_plot <- raw_weight_figure + 
  geom_smooth(data = predicted_weight_average, 
              aes(y = PredWeight, colour = PhotoTreat),
              se = FALSE, method = lm)

# View figure
predicted_weight_plot

# Save figure
ggsave(filename = "Outputs/PupaWeight_predicted.png", 
       plot = predicted_weight_plot,
       device = "png", dpi = "print",
       width = 200, height = 150, units = "mm")


# Fitness curve -------------------------------------------------------------------------------
# This section calculates the fitness curve for each treatment.


## Refit models for fitness -------------------------------------------------------------------

# Refit models for weight and survival without the photoperiod effect (only mismatch and mismatch square)
glm_survival_fitness <- lme4::glmer(Event ~ MismTreat1 + MismTreat2 + (1 | MotherID), 
                                    family = "binomial", 
                                    data = survival_data)
lm_weight_fitness <- lme4::lmer(PupaWeight ~ MismTreat1 + (1 | MotherID), 
                                data = pupa_data)

# Get predictions of survival for fitness curve
# Remove duplicates for each brood since all have same prediction
predict_survival_fitness <- survival_data[!duplicated(survival_data[, c("MotherID", "MismTreatf")]), ]

# Predict probability of dying
predict_survival_fitness$PredDeath <- predict(glm_survival_fitness,
                                              newdata = predict_survival_fitness,
                                              type = "response") 

# Invert for survival probability
predict_survival_fitness$PredSurvival <- (1 - predict_survival_fitness$PredDeath)

# Get predictions of weight for fitness curve
# Remove duplicates for each brood since all have same prediction
predict_weight_fitness <- pupa_data[!duplicated(pupa_data[, c("MotherID", "MismTreatf")]), ]

# Predict weight
predict_weight_fitness$PredWeight <- predict(lm_weight_fitness, 
                                             newdata = predict_weight_fitness,
                                             type = "response")

# View first rows of each set of predictions
head(predict_survival_fitness) 
head(predict_weight_fitness) 


## Fitness analysis --------------------------------------------------------------------------

# Combine weight and survival predictions
relative_fitness <- merge(predict_survival_fitness[, c("MotherID", "MismTreat", "PredSurvival")], 
                          predict_weight_fitness[, c("MotherID", "MismTreat", "PredWeight")], 
                          by = c("MotherID", "MismTreat"), all = TRUE)

# Multiply absolute weight and survival
relative_fitness$Fitness <- relative_fitness$PredSurvival*relative_fitness$PredWeight

# View first rows - NAs occur where no caterpillars survived to pupation
head(relative_fitness) 

# View number of clutches with fitness estimates for each mismatch date
table(relative_fitness$MismTreat, is.na(relative_fitness$Fitness))

relative_fitness$Fitness2 <- ifelse(is.na(relative_fitness$Fitness) == TRUE, 0, relative_fitness$Fitness)

# Fit a loess model to describe the fitness curve
fitness_loess <- loess(Fitness2 ~ -1 + MismTreat,  data = relative_fitness) 
summary(fitness_loess)

# Get predicted fitness curve, starting with index of mismatch dates
fitness_curve <- relative_fitness[!duplicated(relative_fitness[, c("MismTreat")]), ] |>
  select(MismTreat)

# Add predictions from loess model
fitness_curve$PredictedFitness <- predict(fitness_loess, newdata = fitness_curve)
fitness_curve <- arrange(fitness_curve, MismTreat)

# View curve (peaks at day 2)
fitness_curve 

# Calculate relative fitness compared to peak
fitness_curve$RelativeFitness <- fitness_curve$PredictedFitness/filter(fitness_curve, MismTreat == 2)$PredictedFitness
relative_fitness$RelativeFitness <- relative_fitness$Fitness2/mean(filter(relative_fitness, MismTreat == 2)$Fitness2)

# Get mean relative fitness for each mismatch date
relative_fitness_average <- Rmisc::summarySE(relative_fitness, 
                                             measurevar = "RelativeFitness", 
                                             groupvars = c("MismTreat"))

# Get sample size (number of caterpillars)
relative_fitness_average$SampleSize <- aggregate(MotherID ~ MismTreat, data = survival_data, length)$MotherID 
relative_fitness_average$curve <- fitness_curve$RelativeFitness

# View first rows
head(relative_fitness_average)

# Save relative fitness data
write.csv(relative_fitness_average, 
          file = "Outputs/RelativeFitness.csv", row.names = FALSE)


## Relative fitness figure ---------------------------------------------------------------------
# Render relative fitness curve
relative_fitness_plot <- ggplot(data = relative_fitness, 
                                aes(x = MismTreat, y = RelativeFitness)) +
  # Add fitness data points
  geom_jitter(size = 3, alpha = 0.4, height = 0, width = 0.25, shape = 21, 
              fill = "dodgerblue2", colour = "dodgerblue4") +
  # Add mean values
  geom_point(data = relative_fitness_average, size = 5) +
  # Add error bars
  geom_errorbar(data = relative_fitness_average, 
                aes(ymax = RelativeFitness + se, ymin = RelativeFitness - se), width = 0.3) +
  # Add sample size labels
  geom_text(data = relative_fitness_average,
            aes(label = SampleSize, y = RelativeFitness + 0.12), 
            colour = "black", size = 5, fontface = "bold") + 
  geom_hline(yintercept = 1, linetype = "dashed") +
  labs(y = "Relative fitness", x = "Mismatch with oak budburst date (days)") +
  scale_y_continuous(limits = c(0, 1.21), breaks = seq(0, 1.6, by = 0.2)) +
  scale_x_continuous(breaks = seq(-4, 5, by = 1)) + 
  theme(legend.position = "none") +
  theme(axis.title.y = element_text(size = 18, vjust = 2),
        axis.title.x = element_text(size = 18, vjust = -0.5),
        axis.text = element_text(size = 16),
        legend.text = element_text(size = 16),
        legend.title = element_text(size = 17)) +
  theme_cowplot()

# View figure
relative_fitness_plot

# Save figure
ggsave(filename = "Outputs/Output_FitnessCurve_Relative.png",
       plot = relative_fitness_plot, 
       device = "png", dpi = "print",
       width = 200, height = 150, units = "mm")


# Session info --------------------------------------------------------------------------------
sessionInfo() |>
  capture.output(file ="_src/env_CatFoodExp2021_analysis.txt")
