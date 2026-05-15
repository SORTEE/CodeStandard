# Dataset and code for *Phenological mismatch affects individual fitness and population growth in the winter moth*

**Authors:** Natalie E. van Dis (ORCID: [0000-0002-9934-6751](https://orcid.org/0000-0002-9934-6751))

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.8276288.svg)](https://doi.org/10.5281/zenodo.8276288) Version of record scripts

Note: *This is an updated partial version from the [original repository](https://github.com/NEvanDis/WM_fitness). Folder structure and files (incl. only script `1a_CatFoodExp2021_analysis_fitness.R`) of the original repository have been updated to exemplify best coding practices*

## Directory structure

```
.
  |- data
  |- output
    |- fig
    |- result
  |- renv
  |- scripts
    |- 1a_CatFoodExp2021_analysis_fitness.R
  |- .Rprofile
  |- .gitignore
  |- CITATION.cff
  |- CodeStandard.Rproj
  |- LICENSE
  |- README.md
  |- renv.lock
```

## Reproducing analysis

1. Open [`CodeStandard.Rproj`](CodeStandard.Rproj) file in [RStudio](https://posit.co/download/rstudio-desktop/) or other compatible IDE

2. Run [`scripts/1a_CatFoodExp2021_analysis_fitness.R`](scripts/1a_CatFoodExp2021_analysis_fitness.R) script

3. If `data/CatFood2021_deposit.csv` file is not automatically downloaded to `data` folder, download it from <https://doi.org/10.5061/dryad.m905qfv5p> and place in the `data` folder.


## Description of files

| File name | Description |
|-----------|-------------|
| `data/CatFood2021_deposit.csv` | Dataset from the 2021 winter moth caterpillar feeding experiment deposited at Dryad <https://doi.org/10.5061/dryad.m905qfv5p> |
| [`scripts/1a_CatFoodExp2021_analysis_fitness.R`](scripts/1a_CatFoodExp2021_analysis_fitness.R) | `R` script to reproduce the analysis and visualization of the 2021 winter moth caterpillar feeding experiment |
| [`.Rprofile`](.Rprofile) | A configuration file containing `R` code that is automatically executed every time an `R` session starts |
| [`.gitignore`](.gitignore) | A plain text file used to specify files that we do not want Git to track (i.e. that Git should ignore) |
| [`CITATION.cff`](CITATION.cff) | Machine-readable file that specifies how to cite this repository |
| [`CodeStandard.Rproj`](CodeStandard.Rproj) | A project file used by RStudio to define and manage an `R` project |
| [`LICENSE`](LICENSE) | License file specifying how this repository can be reused |
| [`README.md`](README.md) | Description and metadata for this repository |
| [`renv.lock`](renv.lock) | A json file that records all the information needed to recreate the R environment used for analysis |

## Codebook for [`data/CatFood2021_deposit.csv`](data/CatFood2021_deposit.csv)

| Column name         | Description |
|---------------------|-------------|
| ExperimentName      | name of experiment |
| YearCatch           | year in which the parent adult moth(s) were caught | 
| YearHatch           | year in which the eggs hatched |
| TubeID              | id for the female parent |
| AreaShortName       | parent origin area name: `DO` for Doorwerth, `HV` for Hoge Veluwe, `OH` for Oosterhout, and `WA` for Warnsborn |
| Site                | parent origin: id for catch site within area | 
| Tree                | parent origin: id for trees |
| NovemberDate        | parent origin date of catch in November Days i.e. Julian dates with origin `YearCatch`-10-31 | 
| ClutchID            | id for clutch origin of caterpillar |
| CaterpillarID       | id assigned to caterpillar |
| Treatment           | name of assigned treatment |
| HatchAprilDay       | date of hatching in April days (Julian dates with origin 2021-03-31) |
| DeadAprilDay        | date of death in April days, if applicable (Julian dates with origin 2021-03-31) |
| PupationAprilDay    | date of pupation in April days, if applicable (Julian dates with origin 2021-03-31) |
| PupaWeight_ingrams  | weight at pupation in grams |
| AdultNovDate        | date of adult emergence in November days, if applicable (Julian dates with origin 2021-10-31) |
| AdultWeight_ingrams | weight of adults in grams |
| Sex                 | sex of caterpillar (if reached adult stage) |
| Remarks             | any comments related to data point |


## Citation

- van Dis, N. E., Sieperda, G.-J., Bansal, V., van Lith, B., Wertheim, B., & Visser, M. E. (2023). Phenological mismatch affects individual fitness and population growth in the winter moth. *Proceedings of the Royal Society B: Biological Sciences, 290*(2005), 20230414. <https://doi.org/10.1098/rspb.2023.0414>

- van Dis, N., Sieperda, G.-J., Bansal, V., van Lith, B., Wertheim, B., & Visser, M. (2023). *Phenological mismatch affects individual fitness and population growth in the winter moth* [Data set]. Dryad. <https://doi.org/10.5061/dryad.m905qfv5p>

- van Dis, N., Sieperda, G.-J., Bansal, V., van Lith, B., Wertheim, B., & Visser, M. (2023). *Phenological mismatch affects individual fitness and population growth in the winter moth* (version v2) [Computer software]. Zenodo. <https://doi.org/10.5281/zenodo.8276288> 

