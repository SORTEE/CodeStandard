# Analysis of Phenological mismatch experiment 2021 ####
# Manipulated timing of egg hatching of eggs from wild Mothers caught in 2020
# Either hatching on day of budburst (Day0), before (Day-4 to -1), or after (Day+1 to +5)
# Disentangle effects of photoperiod and food quality: photoperiod treatment (changing or constant)


# Open R project in main folder

# Restore library
renv::restore()

# Load packages
#-----------------------------------
library(tidyverse)
library(cowplot)
theme_set(theme_cowplot()) #white background instead of grey -> don't load if want grey grid
library(lme4)
library(lmerTest)
library(Rmisc)


# Load data ####
#-----------------------------------
d <- read.csv("1_data/CatFood2021_deposit.csv")
head(d)

length(unique(d$TubeID)) # should be 22 mothers
table(d$Treatment) # photoperiod and mismatch treatment coded in one variable


# Descriptives
#-----------------------------------

# N per Area
table(d[!duplicated(d$TubeID), "AreaShortName"])


#---------------------------------------------------------------------------------------------------------------------------
# Fitness curve ####
#----------------------------------
# RQ1: What are the fitness consequences of day to day timing (a)synchrony with budburst? ####

# Survival data ####
d_surv <- d %>% mutate(PhotoTreat=gsub("(\\w+)Day.+","\\1",Treatment), MismTreat=gsub("\\w+(Day.+)","\\1",Treatment)) %>% 
  select(TubeID, Treatment, PhotoTreat, MismTreat, CaterpillarID, DeadAprilDay, PupationAprilDay) %>%
  pivot_longer(cols=c(DeadAprilDay, PupationAprilDay), names_to="Info", values_to="TimeOfEvent") %>%
  filter(!is.na(TimeOfEvent)) %>%
  mutate(Event=ifelse(Info=="DeadAprilDay", 1, 0), Treatment=as.factor(Treatment), PhotoTreat=as.factor(ifelse(PhotoTreat=="Chang", "Changing", "Constant")), MismTreatf=as.factor(MismTreat), TubeID=as.factor(TubeID)) %>%
  mutate(Treatment=factor(Treatment, levels=c("ChangDay-4", "ChangDay-3", "ChangDay-2", "ChangDay-1", "ChangDay0", "ChangDay+1", "ChangDay+2", "ChangDay+3", "ChangDay+4",
                                              "ChangDay+5",  "ConstDay-4", "ConstDay-2", "ConstDay0", "ConstDay+2", "ConstDay+4")), 
    MismTreatf=factor(MismTreat, levels=c("Day-4", "Day-3", "Day-2", "Day-1", "Day0", "Day+1", "Day+2", "Day+3", "Day+4", "Day+5")),
    MismTreat=as.numeric(gsub("Day(.+)","\\1",MismTreat))) %>%
  mutate(MismTreat1=MismTreat+5, # no negatives to be able to fit squared term
         MismTreat2=(MismTreat+5)^2) # squared term to add in model
# Vidisha coded it as TimeOfEvent=DeadAprilDay or PupationAprilDay, with event=Died or Survived
head(d_surv)
str(d_surv)
table(d_surv$MismTreat2)

length(unique(d_surv$CaterpillarID)) # should be 976


#-----------------------------------
# Survival analysis ####
#-----------------------------------
levels(d_surv$Treatment)
levels(d_surv$PhotoTreat)
levels(d_surv$MismTreatf) # as factor or not? Marcel thinks not ####
levels(d_surv$TubeID)
table(d_surv$TimeOfEvent)
table(d_surv$Event)

# Visualize survival probabilities ####
head(d_surv)

surv_probs <- aggregate(Event~MismTreat + PhotoTreat + TubeID, d_surv, sum) # per mother
surv_probs$samplesize <- aggregate(Info~MismTreat + PhotoTreat + TubeID, d_surv, length)$Info
surv_probs$probs <- 100 - (surv_probs$Event/surv_probs$samplesize*100) # event = death
head(surv_probs)

surv_avg <- Rmisc::summarySE(surv_probs, measurevar="probs", groupvars=c("MismTreat")) # average of two photoperiod treatments
surv_avg$samplesize <- aggregate(Info~MismTreat, d_surv, length)$Info
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
head(d_surv) # test if probability of survival differs between treatments

glm1 <- glmer(Event ~ (MismTreat1 + MismTreat2)*PhotoTreat + (1|TubeID), family=binomial, data=d_surv,
              na.action="na.fail", control=glmerControl(calc.derivs=F)) # helps convergence
anova1 <- drop1(glm1,test="Chi") %>% as.data.frame # interaction not significant
anova1$mod <- "glm1"

glm2 <- update(glm1, ~ . -MismTreat1:PhotoTreat - MismTreat2:PhotoTreat) # simplify model
anova2 <- drop1(glm2,test="Chi") %>% as.data.frame #no effect of PhotoTreatment, but effect of MismTreat and MismTreat^2
anova2$mod <- "glm2"

# Final model ####
glm_final <- glm2
summary(glm_final)# Estimates are log odds
glm_res <- summary(glm_final)$coefficients %>% as.data.frame

# write.csv(glm_res, file="_results/output_Surv_glmer.csv", row.names=T)
# write.csv(rbind(anova1, anova2), file="_results/anova_Surv_glmer.csv", row.names=T)

# Get predictions ####
glm.pred <- d_surv[!duplicated(d_surv[,c("TubeID", "Treatment")]),] # each replicate assigned same prediction, so remove duplicates
glm.pred$pred <- predict(glm_final, newdata=glm.pred, type="response") # predictions are probability of dying now
glm.pred$survprob <- (1-glm.pred$pred)
aggregate(survprob~MismTreat, data=glm.pred, mean) # peak at Day2
glm.pred$rel <- glm.pred$survprob/mean(filter(glm.pred, MismTreat==1)$survprob) # expressive relative to peak
head(glm.pred)

# Visualize predictions ####
pred <- Rmisc::summarySE(glm.pred, measurevar="survprob", groupvars=c("MismTreat")) # average of two photoperiod treatments
pred$samplesize <- aggregate(CaterpillarID~MismTreat, data=d_surv, length)$CaterpillarID

# Add predictions to raw data figure
p_surv <- raw_surv + #geom_line(data=pred, aes(y=survprob*100)) +
  geom_smooth(data=pred, aes(y=survprob*100), se=F, col="red3")
p_surv
# ggsave(filename="_results/Survival_wpred_rev.png", plot=p_surv, device="png", width=200, height=150, units="mm", dpi="print")

rm(anova1, anova2, glm_res, glm1, glm2, pred, surv_probs, surv_avg, raw_surv) #cleanup


#-----------------------------------
# Pupation weight analysis ####
#-----------------------------------
head(d)

d_pupa <- d %>% mutate(PhotoTreat=gsub("(\\w+)Day.+","\\1",Treatment), MismTreat=gsub("\\w+(Day.+)","\\1",Treatment), PupaWeight=PupaWeight_ingrams*1000) %>%
  select(ExperimentName, TubeID, Treatment, PhotoTreat, MismTreat, CaterpillarID, PupationAprilDay, PupaWeight) %>%
  filter(!is.na(PupationAprilDay)) %>%
  mutate(Treatment=as.factor(Treatment), PhotoTreat=as.factor(ifelse(PhotoTreat=="Chang", "Changing", "Constant")), MismTreatf=as.factor(MismTreat), TubeID=as.factor(TubeID)) %>%
  mutate(Treatment=factor(Treatment, levels=c("ChangDay-4", "ChangDay-3", "ChangDay-2", "ChangDay-1", "ChangDay0", "ChangDay+1", "ChangDay+2", "ChangDay+3", "ChangDay+4",
                                              "ChangDay+5",  "ConstDay-4", "ConstDay-2", "ConstDay0", "ConstDay+2", "ConstDay+4")), 
         MismTreatf=factor(MismTreat, levels=c("Day-4", "Day-3", "Day-2", "Day-1", "Day0", "Day+1", "Day+2", "Day+3", "Day+4", "Day+5")),
         MismTreat=as.numeric(gsub("Day(.+)","\\1",MismTreat))) %>%
  mutate(MismTreat1=MismTreat+5, # no negatives
         MismTreat2=(MismTreat+5)^2) # squared term to add in model
head(d_pupa) # 346 individuals survived until pupation
nrow(d_pupa)/nrow(d)*100 # ~35%


# Visualize ####
weight <- Rmisc::summarySE(d_pupa, measurevar="PupaWeight", groupvars=c("MismTreat", "PhotoTreat"))
weight$pos <- ifelse(is.na(weight$se)==T, 0, weight$se) # position of sample size labels
weight

raw_weight <- ggplot(data=weight, aes(x=MismTreat, y=PupaWeight, col=PhotoTreat, fill=PhotoTreat))+
  scale_colour_manual(values=c("grey27", "orangered2"))+ #"dodgerblue4"
  scale_fill_manual(values=c("grey27", "orangered2"))+
  geom_jitter(data=d_pupa, aes(col=PhotoTreat), alpha=0.3, size=3, height=0, width=0.25)+ #alpha=0.3, size=2, height=0, width=0.25
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
lm1 <- lmer(PupaWeight ~ (MismTreat1 + MismTreat2)*PhotoTreat + (1|TubeID), data=d_pupa)
anova1 <- anova(lm1) %>% as.data.frame() # interaction not significant
anova1$mod <- "lm1"

lm2 <- update(lm1, ~ . - MismTreat1:PhotoTreat - MismTreat2:PhotoTreat) # simplify model
anova2 <- anova(lm2) %>% as.data.frame() # Squared mismatch not significant
anova2$mod <- "lm2"

lm3 <- update(lm2, ~ . - MismTreat2) # simplify model
anova3 <- anova(lm3) %>% as.data.frame() # PhotoTreat and MismTreat significant
anova3$mod <- "lm3"

# Still there if exclude first time point with low sample size?
lm4 <- lmer(PupaWeight ~ -1 + MismTreat1 + PhotoTreat + (1|TubeID), data=filter(d_pupa, MismTreat!=-4))
anova(lm4) # yes


# Final model ####
lm_final <- lm3
summary(lm_final)
lm_res <- summary(lm_final)$coefficients %>% as.data.frame

plot(lm_final) #equal variance? ok
qqnorm(resid(lm_final)) #normally distributed? ok
qqline(resid(lm_final))

# write.csv(lm_res, file="_results/output_PupaWeight_lmer.csv", row.names=T)
# write.csv(rbind(anova1, anova2, anova3), file="_results/anova_PupaWeight_lmer.csv", row.names=T)

# Get predictions ####
lm.pred <- d_pupa[!duplicated(d_pupa[,c("TubeID", "Treatment")]),] # each replicate assigned same prediction, so remove duplicates
lm.pred$pred <- predict(lm_final, newdata=lm.pred, type="response")
head(lm.pred)

# Visualize predictions ####
pred1 <- Rmisc::summarySE(lm.pred, measurevar="pred", groupvars=c("MismTreat", "PhotoTreat")) # significant effect of photoperiod, so show separate means
pred1$samplesize <- weight$N
pred1$pos <- ifelse(is.na(pred1$se)==T, 0, pred1$se) # position of sample size labels

# add predictions to raw data figure
p_weight <- raw_weight + #geom_line(data=pred1, aes(y=pred)) +
  geom_smooth(data=pred1, aes(y=pred, col=PhotoTreat), se=F, method=lm)+
  geom_text(data=filter(weight, PhotoTreat=="Changing"),aes(label=N, y=PupaWeight-pos-1.5), col="black", size=4, fontface="bold")+
  geom_text(data=filter(weight, PhotoTreat=="Constant"),aes(label=N, y=PupaWeight+pos+2.3), col="black", size=4, fontface="bold")
p_weight
# ggsave(filename="_results/PupWeight_wpred_rev.png", plot=p_weight, device="png", width=200, height=150, units="mm", dpi="print")

rm(anova1, anova2, anova3, lm1, lm2, lm3, lm4, lm_res, raw_weight, weight, pred1) # clean up


#--------------------------------------------
# Get fitness curve ####
#--------------------------------------------

# Don't care about PhotoTreat effect, drop from models ####
glm_fit <- glmer(Event ~ MismTreat1 + MismTreat2 + (1 | TubeID), family="binomial", data=d_surv)
lm_fit <- lmer(PupaWeight ~ MismTreat1 + (1 | TubeID), data=d_pupa)

# Get predictions to use for curve ####
glm.fit <- d_surv[!duplicated(d_surv[,c("TubeID", "MismTreatf")]),] # each replicate assigned same prediction, so remove duplicates
glm.fit$pred <- predict(glm_fit, newdata=glm.fit, type="response") # predictions are probability of dying now
glm.fit$survpred <- (1-glm.fit$pred)

lm.fit <- d_pupa[!duplicated(d_pupa[,c("TubeID", "MismTreatf")]),] # each replicate assigned same prediction, so remove duplicates
lm.fit$pred <- predict(lm_fit, newdata=lm.fit, type="response")

head(glm.fit) # pred = probability of dying, survpred=1-pred, 220 observations = 22 mothers * 10 MismTreat groups
head(lm.fit) # pred=predicted weight from lmer, only 154 observations


# Fit curve to absolute fitness ####
#-----------------------------------
RelFit <- merge(glm.fit[,c("TubeID", "MismTreat", "survpred")], lm.fit[,c("TubeID", "MismTreat", "pred")], by=c("TubeID", "MismTreat"), all=T)
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
#RelFit_means$samplesize <- aggregate(TubeID~MismTreat, data=d_pupa, length)$TubeID # number of caterpillars curve is based on
RelFit_means$samplesize <- aggregate(TubeID~MismTreat, data=d_surv, length)$TubeID # number of caterpillars curve is based on = all
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

rm(curve, RelFit_means) # clean up



sessionInfo() %>% capture.output(file="_src/env_CatFoodExp2021_analysis.txt")
