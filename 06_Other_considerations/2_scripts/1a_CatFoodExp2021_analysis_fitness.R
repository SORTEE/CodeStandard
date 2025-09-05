# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Title: Analysis of phenological mismatch experiment 2021
# Author: Natalie E. van Dis
# Email: n.vandis@nioo.knaw.nl
# Date: 2025-08-26
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Paper: van Dis, N. E., Sieperda, G.-J., Bansal, V., van Lith, B., Wertheim, B., & Visser, M. E. (2023). Phenological mismatch affects individual fitness and population growth in the winter moth. Proceedings of the Royal Society B: Biological Sciences, 290(2005), 20230414. https://doi.org/10.1098/rspb.2023.0414

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# 1. Required R packages ####

## 1.1 Restore project library ####
renv::restore()

## 1.2 Load packages ####
library(tidyverse) ## data formatting and visualisation
library(cowplot)   ## arranging plots and clean themes
library(lme4)      ## linear mixed effects modelling
library(lmerTest)  ## anova and summary tables for mixed models
library(Rmisc)     ## functions to assist data analysis
library(rdryad)    ## download data from Dryad

## 1.3 Set theme for plots ####

## plots with white background
theme_set(theme_cowplot()) 

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# Analysis of Phenological mismatch experiment 2021
# Manipulated timing of egg hatching of eggs from wild Mothers caught in 2020
# Either hatching on day of budburst (Day0), before (Day-4 to -1), or after (Day+1 to +5)
# Disentangle effects of photoperiod and food quality: photoperiod treatment (changing or constant)

# before start download the dataset 'CatFood2021_deposit.csv'
# from Dryad repository: https://doi.org/10.5061/dryad.m905qfv5p

# the dataset should be saved in the folder 1_data

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# 2. Data download ####

# The data is deposited in the Dryad repository: https://doi.org/10.5061/dryad.m905qfv5p

# Data citation: van Dis, N., Sieperda, G.-J., Bansal, V., van Lith, B., Wertheim, B., & Visser, M. (2023). Phenological mismatch affects individual fitness and population growth in the winter moth [Data set]. Dryad. https://doi.org/10.5061/dryad.m905qfv5p

## Dryad DOI and file name
doi <- "10.5061/dryad.m905qfv5p"
file_name <- "CatFood2021_deposit.csv"
file_path <- file.path("1_data", file_name)

## Check if data is present in folder
file_exists <- file.exists(file_path)

## If not download using rdryad
if(file_exists == FALSE) {
  ## Download data
  files <- dryad_download(doi)
  ## select dataset
  fileTemp <- files[[doi]][grepl(file_name, files[[doi]])]
  ## read dataset
  d <- read_csv(fileTemp)
  ## save dataset
  write_csv(d, file_path)
}

## If above not works, manually download and place in 1_data

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# 3. Data overview #####

## Load and prepare data
d <- read.csv("1_data/CatFood2021_deposit.csv") |>
  ## rename TubeID to MotherID to match the paper
  dplyr::rename(MotherID = TubeID)

## number of mothers
length(unique(d$MotherID)) ## should be 22 mothers

## treatment-wise observations
table(d$Treatment) ## photoperiod and mismatch treatment coded in one variable

## N per Area
table(d[!duplicated(d$MotherID), "AreaShortName"])

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# 4. Fitness curve ####

# RQ1: What are the fitness consequences of day to day timing (a) synchrony with budburst?

## 4.1 Data preparation ####
d_surv <- d |>
  ## split treatment into components
  mutate(PhotoTreat = gsub("(\\w+)Day.+", "\\1", Treatment),
         MismTreat = gsub("\\w+(Day.+)", "\\1", Treatment)) |>
  select(MotherID, Treatment, PhotoTreat, MismTreat, 
         CaterpillarID, DeadAprilDay, PupationAprilDay) |>
  pivot_longer(cols = c(DeadAprilDay, PupationAprilDay), 
               names_to = "Info", 
               values_to = "TimeOfEvent") |>
  filter(!is.na(TimeOfEvent)) |>
  mutate(Event = ifelse(Info == "DeadAprilDay", 1, 0), 
         Treatment = as.factor(Treatment), 
         PhotoTreat = as.factor(ifelse(PhotoTreat == "Chang",
                                       "Changing", "Constant")),
         MismTreatf = as.factor(MismTreat), 
         MotherID = as.factor(MotherID)) |>
  mutate(Treatment = factor(Treatment, 
                            levels = c("ChangDay-4", "ChangDay-3",
                                       "ChangDay-2", "ChangDay-1",
                                       "ChangDay0",  "ChangDay+1",
                                       "ChangDay+2", "ChangDay+3",
                                       "ChangDay+4", "ChangDay+5", 
                                       "ConstDay-4", "ConstDay-2",
                                       "ConstDay0",  "ConstDay+2",
                                       "ConstDay+4")),
         MismTreatf = factor(MismTreat, 
                             levels = c("Day-4", "Day-3", "Day-2",
                                        "Day-1", "Day0",  "Day+1",
                                        "Day+2", "Day+3", "Day+4",
                                        "Day+5")),
         MismTreat = as.numeric(gsub("Day(.+)", "\\1", MismTreat))
         ) |>
  mutate(
    ## no negatives to be able to fit squared term
    MismTreat1 = MismTreat + 5, 
    ## squared term to add in model
    MismTreat2 = MismTreat1^2
  )

head(d_surv)
str(d_surv)
table(d_surv$MismTreat2)
length(unique(d_surv$CaterpillarID)) # should be 976


## 4.2 Survival analysis ####

levels(d_surv$Treatment)
levels(d_surv$PhotoTreat)
levels(d_surv$MismTreatf)
levels(d_surv$MotherID)
table(d_surv$TimeOfEvent)
table(d_surv$Event) # corresponds to "survival" in the paper

head(d_surv)

surv_probs <- aggregate(Event ~ MismTreat + PhotoTreat + MotherID,
                        d_surv, sum) # per mother


surv_probs$samplesize <- aggregate(Info ~ MismTreat + PhotoTreat +
                                     MotherID, 
                                   d_surv, length)$Info
surv_probs$probs <- 100 - (surv_probs$Event/surv_probs$samplesize*100) # event = death
head(surv_probs)

## average of two photoperiod treatments
surv_avg <- Rmisc::summarySE(surv_probs, measurevar = "probs",
                             groupvars = c("MismTreat")) 
surv_avg$samplesize <- aggregate(Info ~ MismTreat, d_surv, length)$Info

surv_avg

## plot for survival raw data
raw_surv <- ggplot(data = surv_avg, aes(x = MismTreat, y = probs)) +
  scale_colour_manual(values = c("grey27", "orangered2")) + 
  geom_jitter(data = surv_probs, aes(col = PhotoTreat), 
              alpha = 0.3, size = 3, height = 0.5, width = 0.25) +
  geom_point(size = 5, col = "black") +
  geom_errorbar(aes(ymax = probs + se, ymin = probs - se), 
                width = 0.3, col = "black") +
  ## N caterpillars in each treatment
  geom_text(aes(label = samplesize, y = probs + 8.3), 
            col = "black", size = 4, fontface = "bold") + 
  labs(y = "Survival (%)", 
       x = "Mismatch with oak budburst date (days)") +
  scale_y_continuous(breaks = seq(0, 100, by = 10)) +
  scale_x_continuous(breaks = seq(-4, 5, by = 1)) +
  theme(axis.title.y = element_text(size = 18, vjust = 2), 
        axis.title.x = element_text(size = 18, vjust = -0.5),
        axis.text = element_text(size = 16), 
        legend.text = element_text(size = 16), 
        legend.title = element_text(size = 17))

raw_surv 

## save plot
# ggsave(filename = "_results/Survival_raw.png", 
#        plot = raw_surv, device = "png", 
#        width = 200, height = 150, units = "mm", dpi = "print")


## 4.3 Binomial model selection ####

head(d_surv) 

## test if probability of survival differs between treatments
glm1 <- glmer(
  Event ~ (MismTreat1 + MismTreat2) * PhotoTreat + (1 | MotherID), 
  family = binomial, data = d_surv, na.action = "na.fail", 
  ## helps convergence
  control = glmerControl(calc.derivs = FALSE)
)

## Chi square test for significance of interaction
anova1 <- drop1(glm1, test = "Chi") |> 
  as.data.frame()
anova1$mod <- "glm1"

## simplify model
glm2 <- update(
  glm1, ~ . -MismTreat1:PhotoTreat - MismTreat2:PhotoTreat
) 
anova2 <- drop1(glm2, test = "Chi") |> 
  as.data.frame() 
anova2$mod <- "glm2"

## Final model 
glm_final <- glm2
summary(glm_final) # Estimates are log odds
glm_res <- summary(glm_final)$coefficients |> 
  as.data.frame()

# write.csv(glm_res, file = "_results/output_Surv_glmer.csv", 
#           row.names = TRUE)
# write.csv(rbind(anova1, anova2), 
#           file = "_results/anova_Surv_glmer.csv", 
#           row.names = TRUE)

## 4.4 Get predictions ####

## each replicate assigned same prediction, so remove duplicates
glm.pred <- d_surv[!duplicated(d_surv[,c("MotherID", "Treatment")]),] 
# predictions are probability of dying now
glm.pred$pred <- predict(glm_final, newdata = glm.pred, 
                         type = "response")

glm.pred$survprob <- (1 - glm.pred$pred)

aggregate(survprob ~ MismTreat, data = glm.pred, mean) # peak at Day2

glm.pred$rel <- glm.pred$survprob/mean(filter(glm.pred, MismTreat == 1)$survprob) # expressive relative to peak

head(glm.pred)

## 4.5 Visualize predictions ####

# average of two photoperiod treatments
pred <- Rmisc::summarySE(glm.pred, measurevar = "survprob", 
                         groupvars = c("MismTreat")) 
pred$samplesize <- aggregate(CaterpillarID ~ MismTreat, 
                             data = d_surv, length)$CaterpillarID

# Add predictions to raw data figure
p_surv <- raw_surv + 
  # geom_line(data = pred, aes(y = survprob * 100)) +
  geom_smooth(data = pred, aes(y = survprob * 100), 
              se = FALSE, col = "red3")
p_surv

# ggsave(filename = "_results/Survival_wpred_rev.png", 
#        plot = p_surv, device = "png", 
#        width = 200, height = 150, units = "mm", dpi = "print")

rm(anova1, anova2, glm_res, glm1, glm2, pred, 
   surv_probs, surv_avg, raw_surv) #cleanup

## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# 5. Pupation weight analysis ####

head(d)

## 5.1 data preparation ####
d_pupa <- d |> 
  mutate(PhotoTreat = gsub("(\\w+)Day.+", "\\1", Treatment),
         MismTreat = gsub("\\w+(Day.+)", "\\1", Treatment),
         PupaWeight = PupaWeight_ingrams*1000) |>
  select(ExperimentName, MotherID, Treatment, PhotoTreat, 
         MismTreat, CaterpillarID, PupationAprilDay, PupaWeight) |>
  filter(!is.na(PupationAprilDay)) |>
  mutate(Treatment = as.factor(Treatment), 
         PhotoTreat = as.factor(ifelse(PhotoTreat=="Chang",
                                       "Changing", "Constant")),
         MismTreatf = as.factor(MismTreat), 
         MotherID = as.factor(MotherID)) |>
  mutate(
    Treatment = factor(Treatment, 
                       levels = c("ChangDay-4", "ChangDay-3",
                                  "ChangDay-2", "ChangDay-1",
                                  "ChangDay0",  "ChangDay+1",
                                  "ChangDay+2", "ChangDay+3",
                                  "ChangDay+4", "ChangDay+5", 
                                  "ConstDay-4", "ConstDay-2",
                                  "ConstDay0",  "ConstDay+2",
                                  "ConstDay+4")), 
    MismTreatf = factor(MismTreat, 
                        levels = c("Day-4", "Day-3", "Day-2",
                                   "Day-1", "Day0",  "Day+1",
                                   "Day+2", "Day+3", "Day+4", 
                                   "Day+5")),
    MismTreat = as.numeric(gsub("Day(.+)", "\\1", MismTreat))
  ) |>
  mutate(MismTreat1 = MismTreat + 5, # added 5 for no negatives
         MismTreat2 = MismTreat1^2)  # squared term to add in model

## 346 individuals survived until pupation
head(d_pupa) 
nrow(d_pupa)/nrow(d)*100 # ~35%


## 5.2 Visualize ####

weight <- Rmisc::summarySE(d_pupa, measurevar = "PupaWeight",
                           groupvars = c("MismTreat", "PhotoTreat"))
## position of sample size labels
weight$pos <- ifelse(is.na(weight$se) == TRUE, 0, weight$se) 

weight

raw_weight <- ggplot(data = weight, 
                     aes(x = MismTreat, y = PupaWeight, 
                         col = PhotoTreat, fill = PhotoTreat)) +
  scale_colour_manual(values = c("grey27", "orangered2")) + 
  scale_fill_manual(values = c("grey27", "orangered2")) +
  geom_jitter(data = d_pupa, aes(col = PhotoTreat), 
              # alpha = 0.3, size = 2, height = 0, width = 0.25
              alpha = 0.3, size = 3, height = 0, width = 0.25) + 
  geom_errorbar(data = filter(weight, PhotoTreat == "Changing"), 
                aes(ymax = PupaWeight + se, 
                    ymin = PupaWeight - se), 
                width = 0.3, col = "black") +
  geom_errorbar(data = filter(weight, PhotoTreat == "Constant"), 
                aes(ymax = PupaWeight + se, 
                    ymin = PupaWeight - se), 
                width = 0.3, col = "orangered4") +
  geom_point(size = 5, shape = 21, col = "black") +
  labs(y = "Weight at pupation (mg)", 
       x = "Mismatch with oak budburst date (days)") +
  scale_y_continuous(breaks = seq(15, 75, by = 10)) + 
  scale_x_continuous(breaks = seq(-4, 5, by = 1)) +
  theme(axis.title.y = element_text(size = 18, vjust = 2), 
        axis.title.x = element_text(size = 18, vjust = -0.5),
        axis.text = element_text(size = 16), 
        legend.text = element_text(size = 16), 
        legend.title = element_text(size = 17))

raw_weight

# ggsave(filename = "_results/PupWeight_raw.png", 
#        plot = raw_weight , device = "png", 
#        width = 200, height = 150, units = "mm", dpi = "print")

## +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# 6. Fit linear mixed model ####

## 6.1 Model selection ####

## full model
lm1 <- lmer(
  PupaWeight ~ (MismTreat1 + MismTreat2) * PhotoTreat + (1|MotherID),
  data = d_pupa
)

## test significance of interactions
anova1 <- anova(lm1) |> 
  as.data.frame()
anova1$mod <- "lm1"


## simplify model
lm2 <- update(
  lm1, ~ . - MismTreat1:PhotoTreat - MismTreat2:PhotoTreat
) 

## test significance of squared mismatch
anova2 <- anova(lm2) |> 
  as.data.frame() 
anova2$mod <- "lm2"

## simplify model
lm3 <- update(lm2, ~ . - MismTreat2) 

## test significance of PhotoTreat and MismTreat
anova3 <- anova(lm3) |>
  as.data.frame() 
anova3$mod <- "lm3"

## Still there if exclude first time point with low sample size?
lm4 <- lmer(
  PupaWeight ~ -1 + MismTreat1 + PhotoTreat + (1 | MotherID),
  data = filter(d_pupa, MismTreat != -4)
)

anova(lm4)


## 6.2 Model evaluation ####

lm_final <- lm3

summary(lm_final)

lm_res <- summary(lm_final)$coefficients |> 
  as.data.frame()

## model diagnostics

### equal variance
plot(lm_final) 

### normality of residuals
qqnorm(resid(lm_final)) 
qqline(resid(lm_final))

# write.csv(lm_res, file="_results/output_PupaWeight_lmer.csv", 
#           row.names = TRUE)
# write.csv(rbind(anova1, anova2, anova3), 
#           file = "_results/anova_PupaWeight_lmer.csv", 
#           row.names = TRUE)

## 6.3 Get predictions ####

## each replicate assigned same prediction, so remove duplicates
lm.pred <- d_pupa[!duplicated(d_pupa[, c("MotherID", "Treatment")]),]

lm.pred$pred <- predict(lm_final, newdata = lm.pred, 
                        type = "response")
head(lm.pred)

## 6.4 Visualize predictions ####

## significant effect of photoperiod, so show separate means
pred1 <- Rmisc::summarySE(lm.pred, measurevar = "pred", 
                          groupvars = c("MismTreat", "PhotoTreat")) 

pred1$samplesize <- weight$N

## position of sample size labels
pred1$pos <- ifelse(is.na(pred1$se) == TRUE, 0, pred1$se) 

## add predictions to raw data figure
p_weight <- raw_weight + 
  geom_smooth(data = pred1, aes(y = pred, col = PhotoTreat), 
              se = FALSE, method = lm) +
  geom_text(data = filter(weight, PhotoTreat == "Changing"),
            aes(label = N, y = PupaWeight - pos - 1.5), 
            col = "black", size = 4, fontface = "bold") +
  geom_text(data = filter(weight, PhotoTreat == "Constant"),
            aes(label = N, y = PupaWeight + pos + 2.3), 
            col = "black", size = 4, fontface = "bold")
p_weight

# ggsave(filename = "_results/PupWeight_wpred_rev.png", 
#        plot = p_weight, device = "png", 
#        width = 200, height = 150, units = "mm", dpi = "print")

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# 7. Get fitness curve ####

## Don't care about PhotoTreat effect, drop from models
glm_fit <- glmer(Event ~ MismTreat1 + MismTreat2 + (1 | MotherID),
                 family = "binomial", data = d_surv)

lm_fit <- lmer(PupaWeight ~ MismTreat1 + (1 | MotherID), 
               data = d_pupa)

## 7.1 Get predictions to use for curve ####

## each replicate assigned same prediction, so remove duplicates
glm.fit <- d_surv[!duplicated(d_surv[,c("MotherID", "MismTreatf")]),] 
## predictions are probability of dying now
glm.fit$pred <- predict(glm_fit, newdata = glm.fit, 
                        type = "response") 
glm.fit$survpred <- (1 - glm.fit$pred)

## each replicate assigned same prediction, so remove duplicates
lm.fit <- d_pupa[!duplicated(d_pupa[,c("MotherID", "MismTreatf")]),] 

lm.fit$pred <- predict(lm_fit, newdata = lm.fit, type = "response")

## pred = probability of dying, 
## survpred = 1 - pred, 
## 220 observations = 22 mothers * 10 MismTreat groups
head(glm.fit) 

## pred = predicted weight from lmer, 
## only 154 observations 
head(lm.fit) 


## 7.2 Fit curve to absolute fitness ####

RelFit <- merge(
  glm.fit[, c("MotherID", "MismTreat", "survpred")], 
  lm.fit[, c("MotherID", "MismTreat", "pred")], 
  by = c("MotherID", "MismTreat"), all = TRUE
)

colnames(RelFit)[c(3, 4)] <- c("survpred", "pupwpred")

## multiply absolute values
RelFit$Fit <- RelFit$survpred * RelFit$pupwpred 

## can only do for 154 observations, 
## clutches with >=1 caterpillar surviving until pupation
head(RelFit) 

## for the other clutches, fitness = 0
table(RelFit$MismTreat, is.na(RelFit$Fit)) 

RelFit$Fit2 <- ifelse(is.na(RelFit$Fit) == TRUE, 0, RelFit$Fit)

## 7.3 loess model to describe the curve ####

loess_mod <- loess(Fit2 ~ -1 + MismTreat,  data = RelFit) 
summary(loess_mod)

curve <- RelFit[!duplicated(RelFit[, c("MismTreat")]), ] |> 
  select(MismTreat)

curve$pred <- predict(loess_mod, newdata = curve)

curve <- arrange(curve, MismTreat)

curve # peak at day2

## expressive relative to peak
curve$rel <- curve$pred/filter(curve, MismTreat == 2)$pred 

RelFit$rel <- RelFit$Fit2/mean(filter(RelFit, MismTreat == 2)$Fit2)

RelFit_means <- Rmisc::summarySE(RelFit, measurevar = "rel",
                                 groupvars = c("MismTreat"))

# ## number of caterpillars curve is based on
# RelFit_means$samplesize <- aggregate(MotherID ~ MismTreat, 
#                                      data = d_pupa, 
#                                      length)$MotherID 

## number of caterpillars curve is based on = all
RelFit_means$samplesize <- aggregate(MotherID ~ MismTreat, 
                                     data = d_surv,
                                     length)$MotherID 
RelFit_means$curve <- curve$rel

head(RelFit_means)

# write.csv(RelFit_means, file = "_results/RelFitness_rev.csv", 
#           row.names = FALSE)

## plot
p_relfit <- ggplot(data = RelFit, aes(x = MismTreat, y = rel)) +
  geom_jitter(size = 3, alpha = 0.4, 
              height = 0, width = 0.25, shape = 21, 
              fill = "dodgerblue2", col = "dodgerblue4") +
  geom_point(data = RelFit_means, size = 5) +
  geom_errorbar(data = RelFit_means, 
                aes(ymax = rel + se, ymin = rel - se), 
                width = 0.3) +
  # geom_line(data = curve, aes(y = pred), 
  #           col = "darkred", size = 1) +
  ## makes it look more like a smooth line
  # geom_smooth(data = curve, se = FALSE, 
  #             col = "red3", size = 1) + 
  ## number of caterpillars
  geom_text(data = RelFit_means, 
            aes(label = samplesize, y = rel + 0.12), 
            col = "black", size = 5, fontface = "bold") + 
  geom_hline(yintercept = 1, linetype = "dashed") +
  labs(y = "Relative fitness", 
       x = "Mismatch with oak budburst date (days)") +
  scale_y_continuous(lim = c(0, 1.21), 
                     breaks = seq(0, 1.6, by = 0.2)) +
  scale_x_continuous(breaks = seq(-4, 5, by = 1)) + 
  theme(legend.position = "none",
        axis.title.y = element_text(size = 18, vjust = 2), 
        axis.title.x = element_text(size = 18, vjust = -0.5),
        axis.text = element_text(size = 16), 
        legend.text = element_text(size = 16), 
        legend.title = element_text(size = 17))

p_relfit

# ggsave(filename = "_results/FitnessCurve_rev.png", 
#        plot = p_relfit, device = "png", 
#        width = 200, height = 150, units = "mm", dpi = "print")



## capture details of platform and R package versions
sessionInfo() |> 
  capture.output(file = "_src/env_CatFoodExp2021_analysis.txt")
