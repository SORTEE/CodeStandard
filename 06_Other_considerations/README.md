# Dataset and code for *Phenological mismatch affects individual fitness and population growth in the winter moth*

**Authors:** Natalie E. van Dis (ORCID: [0000-0002-9934-6751](https://orcid.org/0000-0002-9934-6751))

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.8276288.svg)](https://doi.org/10.5281/zenodo.8276288) Version of record scripts

Note: *This is a partial copy from the [original repository](https://github.com/NEvanDis/WM_fitness), made for the Hackathon. All the repository is kept same, except the script folder, where you find only the script `1a_CatFoodExp2021_analysis_fitness.R` which is our focus in the hackathon.*

## Directory structure

```
.
  |- 1_data
    |- README.md
  |- 2_scripts
    |- 1a_CatFoodExp2021_analysis_fitness.R
  |- _src
    |- env_CatFoodExp2021_analysis.txt
    |- env_PopDyn_analysis.txt
  |- renv
    |- .gitignore
    |- activate.R
    |- settings.json
  |- .Rprofile
  |- .gitignore
  |- 06_Other_considerations.Rproj
  |- LICENSE
  |- README.md
  |- renv.lock
```

## Description of files

| Filename | Description |
|----------|-------------|
| [`1a_CatFoodExp2021_analysis_fitness.R`](2_scripts/1a_CatFoodExp2021_analysis_fitness.R) | R script to reproduce the analysis and visualization of the 2021 winter moth caterpillar feeding experiment |
| [`env_CatFoodExp2021_analysis.txt`](_src/env_CatFoodExp2021_analysis.txt) | Session information for used platform and R package versions for the analysis of 2021 winter moth caterpillar feeding experiment |
| [`env_PopDyn_analysis.txt`](_src/env_PopDyn_analysis.txt) | Session information for used platform and R package versions for the analysis of winter moth population dynamics |

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

## Citation

- van Dis, N. E., Sieperda, G.-J., Bansal, V., van Lith, B., Wertheim, B., & Visser, M. E. (2023). Phenological mismatch affects individual fitness and population growth in the winter moth. *Proceedings of the Royal Society B: Biological Sciences, 290*(2005), 20230414. <https://doi.org/10.1098/rspb.2023.0414>

- van Dis, N., Sieperda, G.-J., Bansal, V., van Lith, B., Wertheim, B., & Visser, M. (2023). *Phenological mismatch affects individual fitness and population growth in the winter moth* [Data set]. Dryad. <https://doi.org/10.5061/dryad.m905qfv5p>

- van Dis, N., Sieperda, G.-J., Bansal, V., van Lith, B., Wertheim, B., & Visser, M. (2023). *Phenological mismatch affects individual fitness and population growth in the winter moth* (version v2) [Computer software]. Zenodo. <https://doi.org/10.5281/zenodo.8276288> 

