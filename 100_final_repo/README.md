# Dataset and code for *Phenological mismatch affects individual fitness and population growth in the winter moth*

**Authors:** Natalie E. van Dis (ORCID: [0000-0002-9934-6751](https://orcid.org/0000-0002-9934-6751))

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.8276288.svg)](https://doi.org/10.5281/zenodo.8276288) Version of record scripts

Note: *This is an updated partial version from the [original repository](https://github.com/NEvanDis/WM_fitness). All files are the same as in the original repository, except the script folder, where you find only the script `1a_CatFoodExp2021_analysis_fitness.R`*

## Directory structure

```
.
  |- data
  |- scripts
    |- 1a_CatFoodExp2021_analysis_fitness.R
  |- renv
  |- .Rprofile
  |- .gitignore
  |- CodeStandard.Rproj
  |- LICENSE
  |- README.md
  |- renv.lock
```

## Reproducing analysis

1. Open [`CodeStandard.Rproj`](CodeStandard.Rproj) file in [RStudio](https://posit.co/download/rstudio-desktop/) or other compatible IDE

2. Run [`1a_CatFoodExp2021_analysis_fitness.R`](scripts/1a_CatFoodExp2021_analysis_fitness.R) script

3. If [`CatFood2021_deposit.csv`](data/CatFood2021_deposit.csv) file is not automatically downloaded to `data` folder, download it from <https://doi.org/10.5061/dryad.m905qfv5p> and place in the `data` folder.


## Description of files

| File name | Description |
|-----------|-------------|
| [`CatFood2021_deposit.csv`](1_data/CatFood2021_deposit.csv) | Dataset for the 2021 winter moth caterpillar feeding experiment deposited at Dryad <https://doi.org/10.5061/dryad.m905qfv5p> |
| [`1a_CatFoodExp2021_analysis_fitness.R`](2_scripts/1a_CatFoodExp2021_analysis_fitness.R) | `R` script to reproduce the analysis and visualization of the 2021 winter moth caterpillar feeding experiment |
| [`env_CatFoodExp2021_analysis.txt`](_src/env_CatFoodExp2021_analysis.txt) | Session information for used platform and `R` package versions for the analysis of 2021 winter moth caterpillar feeding experiment |
| [`env_PopDyn_analysis.txt`](_src/env_PopDyn_analysis.txt) | Session information for used platform and `R` package versions for the analysis of winter moth population dynamics |
| [`.Rprofile`](.Rprofile) | A plain text file containing `R` code that is automatically executed every time an `R` session starts |
| [`.gitignore`](.gitignore) | A plain text file used to specify intentionally untracked files that Git should ignore |
| [`CodeStandard.Rproj`](CodeStandard.Rproj) | A project file used by RStudio to define and manage an `R` project |
| [`LICENSE`](LICENSE) | Licence file for reusing the repository |
| [`README.md`](README.md) | Description and metadata for repository |
| [`renv.lock`](renv.lock) | A json file that records all the information needed to recreate the project in future |

## Codebook for [`CatFood2021_deposit.csv`](1_data/CatFood2021_deposit.csv)

| Column name         | Description |
|---------------------|-------------|
| ExperimentName      | name of experiment |
| YearCatch           | year in which the caterpillar caught | 
| YearHatch           | year in which the eggs were hatched |
| TubeID              | id for the female parent |
| AreaShortName       | name of area: `DO` for Doorwerth, `HV` for Hoge Veluwe, `OH` for Oosterhout, and `WA` for Warnsborn |
| Site                | id for sites | 
| Tree                | id for trees |
| NovemberDate        | date of catch in November Days i.e. Julian dates with origin `YearCatch`-10-31 | 
| ClutchID            | id for origin of caterpillar |
| CaterpillarID       | id assigned to caterpillar |
| Treatment           | name of assigned treatment |
| HatchAprilDay       | date of hatching in April days (Julian dates with origin 2021-03-31) |
| DeadAprilDay        | date of death in April days, if applicable (Julian dates with origin 2021-03-31) |
| PupationAprilDay    | date of pupation in April days, if applicable (Julian dates with origin 2021-03-31) |
| PupaWeight_ingrams  | weight at pupation in grams |
| AdultNovDate        | date of adult emergence in November days, if applicable (Julian dates with origin 2021-10-31) |
| AdultWeight_ingrams | weight of adults in grams |
| Sex                 | sex of adults |
| Remarks             | any specific comment for observation |


## Citation

- van Dis, N. E., Sieperda, G.-J., Bansal, V., van Lith, B., Wertheim, B., & Visser, M. E. (2023). Phenological mismatch affects individual fitness and population growth in the winter moth. *Proceedings of the Royal Society B: Biological Sciences, 290*(2005), 20230414. <https://doi.org/10.1098/rspb.2023.0414>

- van Dis, N., Sieperda, G.-J., Bansal, V., van Lith, B., Wertheim, B., & Visser, M. (2023). *Phenological mismatch affects individual fitness and population growth in the winter moth* [Data set]. Dryad. <https://doi.org/10.5061/dryad.m905qfv5p>

- van Dis, N., Sieperda, G.-J., Bansal, V., van Lith, B., Wertheim, B., & Visser, M. (2023). *Phenological mismatch affects individual fitness and population growth in the winter moth* (version v2) [Computer software]. Zenodo. <https://doi.org/10.5281/zenodo.8276288> 

