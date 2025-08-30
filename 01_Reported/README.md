*This is a partial copy from the [original repository](https://github.com/NEvanDis/WM_fitness), made for the Hackathon.  
We kept all the repository the same, except the script folder. There you find only the script `1a_CatFoodExp2021_analysis_fitness.R` which is our focus in the hackathon.*


[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.8276288.svg)](https://doi.org/10.5281/zenodo.8276288) Version of record scripts

# Winter moth individual fitness and population growth
This folder contains all the scripts needed to reproduce the analysis of experimental and field winter moth data belonging to manuscript _Phenological mismatch affects individual fitness and population growth in the winter moth_, published in Proc Roy Soc B: https://doi.org/10.1098/rspb.2023.0414

**NB: The raw data, including both experimental data and field data, can be found on Dryad https://doi.org/10.5061/dryad.m905qfv5p**

&nbsp;

## Authors
Natalie E. van Dis, ORCID ID: 0000-0002-9934-6751

&nbsp;

## Analysis and visualization of Experimental data
R scripts to reproduce the analysis and visualization (incl. manuscript figures) of the 2021 winter moth caterpillar feeding experiment:

### Script: ```2_scripts/1a_CatFoodExp2021_analysis_fitness.R ```
(1) What are the fitness consequences of day to day timing (a)synchrony with budburst?

### Script: ```2_scripts/1b_CatFoodExp2021_analysis_devtime.R ```
(2) Can food quality affect the timing of life stages?

### Script: ```2_scripts/suppl_pupaweight_proxy.R ```
Supplemental: Is pupation weight a good proxy for fecundity?

#### Generated Output
The 1a_CatFoodExp2021_analysis_fitness.R script generates output files saved to the `_results` directory. 
These files include data tables and plots that can be used to reproduce the paper's findings.

`_results/output_Surv_glmer.csv`: Contains the model coefficients from the final binomial mixed-effects model for survival.

`_results/anova_Surv_glmer.csv`: Presents the ANOVA results (Chi-square test statistics and p-values) for the survival mixed-effects models.

`_results/Survival_raw.png`: A plot visualizing the raw survival probabilities of caterpillars across different mismatch treatments.

`_results/Survival_wpred_rev.png`: The raw survival plot with an added curve representing the predicted survival probabilities from the statistical model.

`_results/output_PupaWeight_lmer.csv`: Contains the model coefficients from the final linear mixed-effects model for pupation weight.

`_results/anova_PupaWeight_lmer.csv`: Presents the ANOVA results for the pupation weight mixed-effects models.

`_results/PupWeight_raw.png`: A plot of the raw pupation weights, separated by photoperiod treatment.

`_results/PupWeight_wpred_rev.png`: The raw pupation weight plot with added lines representing the predicted values from the statistical model.

`_results/RelFitness_rev.csv`: A data table summarizing the calculated relative fitness for each mismatch treatment day.

`_results/FitnessCurve_rev.png`: A plot of the relative fitness curve, combining the predicted survival and pupation weight data.

_src/env_CatFoodExp2021_analysis.txt: A text file with the session information, including the R version and all loaded package versions.

See ```_src/env_CatFoodExp2021_analysis.txt``` for used R package versions.

&nbsp;

## Analysis and visualization of long-term Field data
### Script: ```2_scripts/2_prep_FieldData.R ```
R script to get trapping effort descriptives and to prep all the field data for analysis.

### Script: ```2_scripts/3_plot_popnum.R ```
R script to reproduce the manuscript figure that visualizes winter moth population dynamics and population phenological mismatch over time (1993-2021) at four locations in the Netherlands.

### Script: ```2_scripts/4_popdyn_analysis.R ```
R script to reproduce the analysis of winter moth population dynamics: how much variation in population growth can be explained by timing mismatch?

See ```_src/env_PopDyn_analysis.txt``` for used R package versions.
