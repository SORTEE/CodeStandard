# Dataset and code for *[Project Title]*

**Authors:** [Author name(s)] (ORCID: [0000-0000-0000-0000](https://orcid.org/0000-0000-0000-0000))

**DOI:** <https://doi.org/[DOI]> *(optional: link to version of record data and scripts)*

## Repository structure

```
.
  |- data
    |- raw
    |- processed
  |- output
    |- fig
    |- result
  |- scripts
    |- script_template.R
  |- .Rprofile
  |- .gitignore
  |- CITATION_template.cff
  |- [ProjectName].Rproj
  |- LICENSE
  |- README_template.md
```

## Reproducing the analysis

1. Open `[ProjectName].Rproj` file in [RStudio](https://posit.co/download/rstudio-desktop/) or other compatible IDE

2. Run scripts/* *(optional: specify script order if applicable)*

3. Place the required data in the `data/` folder (if not downloaded automatically)


## Description of files

| File name | Description |
|-----------|-------------|
| `data/raw/` | Raw input data (e.g. observed field counts) |
| `data/processed/` | Processed input data (data that has been processed before analysis e.g. pixel brightness of images) |
| `output/` | Folders to store script generated results and figures |
| [`scripts/script_template.R`](scripts/script_template.R) | Analysis script (template) |
| [`.Rprofile`](.Rprofile) | A configuration file containing `R` code that is automatically executed every time an `R` session starts |
| [`.gitignore`](.gitignore) | A plain text file used to specify files that we do not want Git to track (i.e. that Git should ignore) |
| `*.gitkeep` | Empty placeholder file to make sure git will track directory structure but not directory content of the data and output folders |
| [`CITATION_template.cff`](CITATION_template.cff) | Machine-readable file that specifies how to cite this repository (template) |
| [`[ProjectName].Rproj`](ProjectName.Rproj) | A project file used by RStudio to define and manage an `R` project |
| [`LICENSE`](LICENSE) | License file specifying how this repository can be reused |
| [`README_template.md`](README_template.md) | Description and metadata for this repository (template) |


## Codebook for `data/*`

| Column name         | Description |
|---------------------|-------------|
| Variable1		      | description of Variable1 |
| Variable2		      | description of Variable1 |
| Variable3		      | description of Variable1 |


## Citation

If you use this repository, please cite:

- **Article:** Author(s). (Year). *Title*. Journal. <https://doi.org/[DOI]>
- **Dataset:** Author(s). (Year). *Dataset title* [Data set]. Data Repository. <https://doi.org/[DOI]>
- **Code:** Author(s). (Year). *Repository title* [Computer software]. Code Repository. <https://doi.org/[DOI]>