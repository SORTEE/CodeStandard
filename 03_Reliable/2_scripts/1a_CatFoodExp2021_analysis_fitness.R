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

# Load packages
#-----------------------------------
library(Rmisc)
library(tidyverse)
library(cowplot)
theme_set(theme_cowplot()) #white background instead of grey -> don't load if want grey grid
library(lme4)
library(lmerTest)


# Load data ####
#-----------------------------------
catDataRaw <- read.csv("1_data/CatFood2021_deposit.csv")
head(catDataRaw)

# renaming TubeID as MotherID to match the terminology used in the Statistical section of the paper
catData <- rename(catDataRaw, MotherID = TubeID)

length(unique(catData$MotherID)) # should be 22 mothers
table(catData$Treatment) # photoperiod and mismatch treatment coded in one variable


# Descriptives
#-----------------------------------

# N per Area
table(catData[!duplicated(catData$MotherID), "AreaShortName"])


#---------------------------------------------------------------------------------------------------------------------------
# Fitness curve ####
#----------------------------------
# RQ1: What are the fitness consequences of day to day timing (a)synchrony with budburst? ####

# Survival data ####
catData_surv <- catData %>% mutate(PhotoTreat=gsub("(\\w+)Day.+","\\1",Treatment), MismTreat=gsub("\\w+(Day.+)","\\1",Treatment)) %>% 
  select(MotherID, Treatment, PhotoTreat, MismTreat, CaterpillarID, DeadAprilDay, PupationAprilDay) %>%
  pivot_longer(cols=c(DeadAprilDay, PupationAprilDay), names_to="Info", values_to="TimeOfEvent") %>%
  filter(!is.na(TimeOfEvent)) %>%
  mutate(Event=ifelse(Info=="DeadAprilDay", 1, 0), Treatment=as.factor(Treatment), PhotoTreat=as.factor(ifelse(PhotoTreat=="Chang", "Changing", "Constant")), MismTreat_factor=as.factor(MismTreat), MotherID=as.factor(MotherID)) %>%
  mutate(Treatment_relevelled=factor(Treatment, levels=c("ChangDay-4", "ChangDay-3", "ChangDay-2", "ChangDay-1", "ChangDay0", "ChangDay+1", "ChangDay+2", "ChangDay+3", "ChangDay+4",
                                                         "ChangDay+5",  "ConstDay-4", "ConstDay-2", "ConstDay0", "ConstDay+2", "ConstDay+4")), 
         MismTreat_factor=factor(MismTreat, levels=c("Day-4", "Day-3", "Day-2", "Day-1", "Day0", "Day+1", "Day+2", "Day+3", "Day+4", "Day+5")),
         MismTreat=as.numeric(gsub("Day(.+)","\\1",MismTreat))) %>%
  mutate(MismTreat_noNeg=MismTreat+5, # no negatives to be able to fit squared term
         MismTreat_squared=(MismTreat+5)^2) # squared term to add in model
# Vidisha coded it as TimeOfEvent=DeadAprilDay or PupationAprilDay, with event=Died or Survived
head(catData_surv)
str(catData_surv)
table(catData_surv$MismTreat_squared)

length(unique(catData_surv$CaterpillarID)) # should be 976


#-----------------------------------
# Survival analysis ####
#-----------------------------------
levels(catData_surv$Treatment_relevelled)
levels(catData_surv$PhotoTreat)
levels(catData_surv$MismTreat_factor) # as factor or not? Marcel thinks not ####
levels(catData_surv$MotherID)
table(catData_surv$TimeOfEvent)
table(catData_surv$Event) # this variable corresponds to "survival" as defined in the paper (e.g., the response variable in the first binomial mixed-effect model)

# Visualize survival probabilities ####
head(catData_surv)

surv_probs <- aggregate(Event~MismTreat + PhotoTreat + MotherID, catData_surv, sum) # per mother
surv_probs$samplesize <- aggregate(Info~MismTreat + PhotoTreat + MotherID, catData_surv, length)$Info
surv_probs$probs <- 100 - (surv_probs$Event/surv_probs$samplesize*100) # event = death
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
# ggsave(filename="_results/Survival_raw.png", plot=raw_surv , device="png", width=200, height=150, units="mm", dpi="print")


# Fit binomial model ####
#-----------------------------------
head(catData_surv) # test if probability of survival differs between treatments

glmSurv_step1 <- glmer(Event ~ (MismTreat_noNeg + MismTreat_squared)*PhotoTreat + (1|MotherID), family=binomial, data=catData_surv,
                       na.action="na.fail", control=glmerControl(calc.derivs=F)) # helps convergence
anovaSurv_step1 <- drop1(glmSurv_step1,test="Chi") %>% as.data.frame # interaction not significant; the use of Chi-square test to determine statistical significance should be explicitly mention in the paper
anovaSurv_step1$mod <- "glmSurv_step1"

glmSurv_step2 <- update(glmSurv_step1, ~ . -MismTreat_noNeg:PhotoTreat - MismTreat_squared:PhotoTreat) # simplify model
anovaSurv_step2 <- drop1(glmSurv_step2,test="Chi") %>% as.data.frame #no effect of PhotoTreatment, but effect of MismTreat and MismTreat^2
anovaSurv_step2$mod <- "glmSurv_step2"

# Final model ####
glmSurv_final <- glmSurv_step2
summary(glmSurv_final)# Estimates are log odds
glmSurv_res <- summary(glmSurv_final)$coefficients %>% as.data.frame

# write.csv(glmSurv_res, file="_results/output_Surv_glmer.csv", row.names=T)
# write.csv(rbind(anovaSurv_step1, anovaSurv_step2), file="_results/anova_Surv_glmer.csv", row.names=T)

# Get predictions ####
glmSurv_pred <- catData_surv[!duplicated(catData_surv[,c("MotherID", "Treatment_relevelled")]),] # each replicate assigned same prediction, so remove duplicates
glmSurv_pred$pred <- predict(glmSurv_final, newdata=glmSurv_pred, type="response") # predictions are probability of dying now
glmSurv_pred$survprob <- (1-glmSurv_pred$pred)
aggregate(survprob~MismTreat, data=glmSurv_pred, mean) # peak at Day2
glmSurv_pred$rel <- glmSurv_pred$survprob/mean(filter(glmSurv_pred, MismTreat==1)$survprob) # expressive relative to peak
head(glmSurv_pred)

# Visualize predictions ####
pred_surv <- Rmisc::summarySE(glmSurv_pred, measurevar="survprob", groupvars=c("MismTreat")) # average of two photoperiod treatments
pred_surv$samplesize <- aggregate(CaterpillarID~MismTreat, data=catData_surv, length)$CaterpillarID

# Add predictions to raw data figure
p_surv <- raw_surv + #geom_line(data=pred, aes(y=survprob*100)) +
  geom_smooth(data=pred_surv, aes(y=survprob*100), se=F, col="red3")
p_surv
# ggsave(filename="_results/Survival_wpred_rev.png", plot=p_surv, device="png", width=200, height=150, units="mm", dpi="print")

rm(anovaSurv_step1, anovaSurv_step2, glmSurv_res, glmSurv_step1, glmSurv_step2, pred_surv, surv_probs, surv_avg, raw_surv) #cleanup


#-----------------------------------
# Pupation weight analysis ####
#-----------------------------------

catData_pupa <- catData %>% mutate(PhotoTreat=gsub("(\\w+)Day.+","\\1",Treatment), MismTreat=gsub("\\w+(Day.+)","\\1",Treatment), PupaWeight=PupaWeight_ingrams*1000) %>%
  select(ExperimentName, MotherID, Treatment, PhotoTreat, MismTreat, CaterpillarID, PupationAprilDay, PupaWeight) %>%
  filter(!is.na(PupationAprilDay)) %>%
  mutate(Treatment=as.factor(Treatment), PhotoTreat=as.factor(ifelse(PhotoTreat=="Chang", "Changing", "Constant")), MismTreat_factor=as.factor(MismTreat), MotherID=as.factor(MotherID)) %>%
  mutate(Treatment_relevelled=factor(Treatment, levels=c("ChangDay-4", "ChangDay-3", "ChangDay-2", "ChangDay-1", "ChangDay0", "ChangDay+1", "ChangDay+2", "ChangDay+3", "ChangDay+4",
                                                         "ChangDay+5",  "ConstDay-4", "ConstDay-2", "ConstDay0", "ConstDay+2", "ConstDay+4")), 
         MismTreat_factor=factor(MismTreat, levels=c("Day-4", "Day-3", "Day-2", "Day-1", "Day0", "Day+1", "Day+2", "Day+3", "Day+4", "Day+5")),
         MismTreat=as.numeric(gsub("Day(.+)","\\1",MismTreat))) %>%
  mutate(MismTreat_noNeg=MismTreat+5, # no negatives
         MismTreat_squared=(MismTreat+5)^2) # squared term to add in model
head(catData_pupa) # 346 individuals survived until pupation
nrow(catData_pupa)/nrow(catData)*100 # ~35%


# Visualize ####
weight <- Rmisc::summarySE(catData_pupa, measurevar="PupaWeight", groupvars=c("MismTreat", "PhotoTreat"))
weight$pos <- ifelse(is.na(weight$se)==T, 0, weight$se) # position of sample size labels
weight

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
# ggsave(filename="_results/PupWeight_raw.png", plot=raw_weight , device="png", width=200, height=150, units="mm", dpi="print")


# Fit linear mixed model ####
#-----------------------------------
lmPupa_step1 <- lmer(PupaWeight ~ (MismTreat_noNeg + MismTreat_squared)*PhotoTreat + (1|MotherID), data=catData_pupa)
anovaPupa_step1 <- anova(lmPupa_step1) %>% as.data.frame() # interaction not significant
anovaPupa_step1$mod <- "lmPupa_step1"

lmPupa_step2 <- update(lmPupa_step1, ~ . - MismTreat_noNeg:PhotoTreat - MismTreat_squared:PhotoTreat) # simplify model
anovaPupa_step2 <- anova(lmPupa_step2) %>% as.data.frame() # Squared mismatch not significant
anovaPupa_step2$mod <- "lmPupa_step2"

lmPupa_step3 <- update(lmPupa_step2, ~ . - MismTreat_squared) # simplify model
anovaPupa_step3 <- anova(lmPupa_step3) %>% as.data.frame() # PhotoTreat and MismTreat significant
anovaPupa_step3$mod <- "lmPupa_step3"

# Still there if exclude first time point with low sample size?
lmPupa_step3_excludeOutlier <- lmer(PupaWeight ~ -1 + MismTreat_noNeg + PhotoTreat + (1|MotherID), data=filter(catData_pupa, MismTreat!=-4))
anova(lmPupa_step3_excludeOutlier) # yes


# Final model ####
lmPupa_final <- lmPupa_step3
summary(lmPupa_final)
lmPupa_res <- summary(lmPupa_final)$coefficients %>% as.data.frame

plot(lmPupa_final) #equal variance? ok
qqnorm(resid(lmPupa_final)) #normally distributed? ok
qqline(resid(lmPupa_final))

# write.csv(lmPupa_res, file="_results/output_PupaWeight_lmer.csv", row.names=T)
# write.csv(rbind(anovaSurv_step1, anovaSurv_step2, anova3), file="_results/anova_PupaWeight_lmer.csv", row.names=T)

# Get predictions ####
lmPupa_pred <- catData_pupa[!duplicated(catData_pupa[,c("MotherID", "Treatment_relevelled")]),] # each replicate assigned same prediction, so remove duplicates
lmPupa_pred$pred <- predict(lmPupa_final, newdata=lmPupa_pred, type="response")
head(lmPupa_pred)

# Visualize predictions ####
pred_pupa <- Rmisc::summarySE(lmPupa_pred, measurevar="pred", groupvars=c("MismTreat", "PhotoTreat")) # significant effect of photoperiod, so show separate means
pred_pupa$samplesize <- weight$N
pred_pupa$pos <- ifelse(is.na(pred_pupa$se)==T, 0, pred_pupa$se) # position of sample size labels

# add predictions to raw data figure
p_weight <- raw_weight + #geom_line(data=pred_pupa, aes(y=pred)) +
  geom_smooth(data=pred_pupa, aes(y=pred, col=PhotoTreat), se=F, method=lm)+
  geom_text(data=filter(weight, PhotoTreat=="Changing"),aes(label=N, y=PupaWeight-pos-1.5), col="black", size=4, fontface="bold")+
  geom_text(data=filter(weight, PhotoTreat=="Constant"),aes(label=N, y=PupaWeight+pos+2.3), col="black", size=4, fontface="bold")
p_weight
# ggsave(filename="_results/PupWeight_wpred_rev.png", plot=p_weight, device="png", width=200, height=150, units="mm", dpi="print")



#--------------------------------------------
# Get fitness curve ####
#--------------------------------------------

# Don't care about PhotoTreat effect, drop from models ####
modelSurv_fitness <- glmer(Event ~ MismTreat_noNeg + MismTreat_squared + (1 | MotherID), family="binomial", data=catData_surv)
modelPupa_fitness <- lmer(PupaWeight ~ MismTreat_noNeg + (1 | MotherID), data=catData_pupa)

# Get predictions to use for curve ####
predSurv_fitness <- catData_surv[!duplicated(catData_surv[,c("MotherID", "MismTreat_factor")]),] # each replicate assigned same prediction, so remove duplicates
predSurv_fitness$pred <- predict(modelSurv_fitness, newdata=predSurv_fitness, type="response") # predictions are probability of dying now
predSurv_fitness$survpred <- (1-predSurv_fitness$pred)

predPupa_fitness <- catData_pupa[!duplicated(catData_pupa[,c("MotherID", "MismTreat_factor")]),] # each replicate assigned same prediction, so remove duplicates
predPupa_fitness$pred <- predict(modelPupa_fitness, newdata=predPupa_fitness, type="response")

head(predSurv_fitness) # pred = probability of dying, survpred=1-pred, 220 observations = 22 mothers * 10 MismTreat groups
head(predPupa_fitness) # pred=predicted weight from lmer, only 154 observations


# Fit curve to absolute fitness ####
#-----------------------------------
RelFit <- merge(predSurv_fitness[,c("MotherID", "MismTreat", "survpred")], predPupa_fitness[,c("MotherID", "MismTreat", "pred")], by=c("MotherID", "MismTreat"), all=T)
colnames(RelFit)[c(3,4)] <- c("survpred", "pupwpred")
RelFit$Fit <- RelFit$survpred*RelFit$pupwpred # multiply absolute values
head(RelFit) # can only do for 154 observations, clutches with >=1 caterpillar surviving until pupation
table(RelFit$MismTreat, is.na(RelFit$Fit)) # for the other clutches, fitness = 0
RelFit$Fit2 <- ifelse(is.na(RelFit$Fit)==T, 0, RelFit$Fit)

# loess model to describe the curve ####
loess_mod <- loess(Fit2~ -1 + MismTreat,  data=RelFit) 
summary(loess_mod)

curve <- RelFit[!duplicated(RelFit[,c("MismTreat")]),] %>% select(MismTreat)
curve$pred <- predict(loess_mod, newdata=curve)
curve <- arrange(curve, MismTreat)
curve # peak at day2
curve$rel <- curve$pred/filter(curve, MismTreat==2)$pred # expressive relative to peak

RelFit$rel <- RelFit$Fit2/mean(filter(RelFit, MismTreat==2)$Fit2)

RelFit_means <- Rmisc::summarySE(RelFit, measurevar="rel", groupvars=c("MismTreat"))
#RelFit_means$samplesize <- aggregate(MotherID~MismTreat, data=catData_pupa, length)$MotherID # number of caterpillars curve is based on
RelFit_means$samplesize <- aggregate(MotherID~MismTreat, data=catData_surv, length)$MotherID # number of caterpillars curve is based on = all
RelFit_means$curve <- curve$rel
head(RelFit_means)
# write.csv(RelFit_means, file="_results/RelFitness_rev.csv", row.names=F)

p_relfit <- ggplot(data=RelFit, aes(x=MismTreat, y=rel)) +
  geom_jitter(size=3, alpha=0.4, height=0, width=0.25, shape=21, fill="dodgerblue2", col="dodgerblue4")+
  geom_point(data=RelFit_means, size=5) +
  geom_errorbar(data=RelFit_means, aes(ymax = rel+se, ymin=rel-se), width=0.3) +
  #geom_line(data=curve, aes(y=pred), col="darkred", size=1)+
  #geom_smooth(data=curve, se=F, col="red3", size=1)+ # makes it look more like a smooth line, but otherwise exactly the same as using geom_line
  geom_text(data=RelFit_means,aes(label=samplesize, y=rel+0.12), col="black", size=5, fontface="bold")+ # number of caterpillars
  geom_hline(yintercept=1, linetype="dashed")+
  labs(y="Relative fitness", x="Mismatch with oak budburst date (days)")+
  scale_y_continuous(lim=c(0,1.21), breaks=seq(0,1.6, by=0.2))+ scale_x_continuous(breaks=seq(-4,5, by=1))+ #lim=c(-0.1,1.3)
  theme(legend.position="none")+
  theme(axis.title.y=element_text(size=18, vjust=2), axis.title.x=element_text(size=18, vjust=-0.5),
        axis.text=element_text(size=16), legend.text = element_text(size=16), legend.title=element_text(size=17))
p_relfit
# ggsave(filename="_results/FitnessCurve_rev.png", plot=p_relfit, device="png", width=200, height=150, units="mm", dpi="print")




sessionInfo() %>% capture.output(file="_src/env_CatFoodExp2021_analysis.txt")

