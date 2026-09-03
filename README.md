# A Code Standard for Ecology and Evolution

**Authors:** Arthur V. Rodrigues, Cecilia Baldoni, Mattia Ghilardi, Saoirse Kelleher, Abhishek Kumar, Martin Luquet, Charlotte Recapet, Kevin R. Bairos-Novak, Giulia Masoero, Matthieu Paquet, Alfredo Sánchez-Tójar, Saeed Shafiei Sabet, Gabe Winter & Natalie E. van Dis

The [Code Standard](CodeStandard/) is a piece of R code with accompanying metadata files that can be used as an accessible and easy way to implement transparent and reproducible practices in your own coding by example. To enable easy implementation of Open, Reliable, and Transparent (ORT) best practices for code sharing, we also offer a [repository template](Templates/) that you can download to get started with preparing your code for sharing, including clear folder structure, a README file template, analysis script templates, and more.

The Code Standard was created by members of the Society for Open, Reliable, and Transparent Ecology and Evolutionary Biology ([SORTEE](https://sortee.org/)), coming together as a community to discuss good code sharing practices in Ecology and Evolution as part of a [Hackathon](Hackathon/) to review and rewrite an existing piece of R code coming from a published paper (see details in Rodrigues et al. 2026).

The Top10 Open, Reliable and Transparent (ORT) practices that we consider to be essential for code sharing in Ecology and Evolution and beyond are:

| Rank | Topic | ORT practice |
|------|-------|--------------|
| 1 | Run | Ensure that your code runs without error and mistakes |
| 2 | Reported | Ensure that shared code matches the methods description in the associated paper |
| 3 | Reproducible | Ensure that all results, figures, and conclusions are reproducible from the code |
| 4 | Reported, Reliable, Organisation & Structure | Extensively comment your scripts |
| 5 | Run, Organisation & Structure | Use an appropriate folder structure for your project |
| 6 | Other | Ensure that data and code adhere to the FAIR principles: Findable, Accessible, Interoperable and Reusable |
| 7 | Reliable | Ensure that your code is reliable, meaning that it runs and completes as intended |
| 8 | Run, Organisation & Structure | Have code with a clear structure |
| 9 | Other | Provide clear and complete documentation (i.e. README and metadata) |
| 10 | Reproducible | Record and report required softwares, packages and their versions |

In total, we identified 39 best practices for code sharing (see Rodrigures et al. 2026).


## How to use this repository

This repository has three folders, with their respective README files:

```         
  |- CodeStandard
  |- Hackathon
  |- Templates
```

You can use [`{git}`](https://git-scm.com/) to download the full repository to your machine:
```
git clone https://github.com/SORTEE/CodeStandard.git
```

### `CodeStandard` folder
In [`CodeStandard`](CodeStandard/) you will find the example code and support documentation implementing Open, Reliable and Transparent (ORT) best practices for code sharing.

For this practical example, we chose a relatively simple and common ecology and evolution analysis that constructs a fitness curve from experimental data, coming from a published paper (van Dis et al. 2023). As such, [the Code Standard analysis script](CodeStandard/scripts/1a_CatFoodExp2021_analysis_fitness.R) offers all basic steps in an analysis workflow: loading required packages, exploring the data, data preparation, fitting a model, summarizing results and creating visualization outputs. 

In addition to the analysis script, the `CodeStandard` also implements best practices for code support documentation including recording software versions via [`{renv}`](CodeStandard/renv.lock), using an appropriate [folder structure](CodeStandard/), and clear and complete documentation (e.g. a clear [README file](CodeStandard/README.md)). 

*The `CodeStandard` folder is intended to serve as a reference for good practices in code sharing. The place you return to whenever you need an example of how to implement an ORT practice in your own coding.*

### `Hackathon` folder
We also share the [`Hackathon`](Hackathon/) repository that was used to create the Code Standard. In this folder, you can find [the original code and supporting documentation](Hackathon/00_base_code), as well as folders for each of the focus areas of code review (i.e. Reported, Run, Reliable, Reproducible, Organisation & Structure, and Other considerations) and other auxiliary documentation used during the hackathon. More supporting files can be found on [OSF](https://osf.io/762u4/).

We share the `Hackathon` repository to ensure transparency on how the Code Standard was created, and to allow for the intermediate files and Hackathon structure to be used for teaching purposes. For example, it can be used as a reference to organize your own hackathon to create code standards for other often-used analyses in Ecology and Evolution.

### `Templates` folder
The [`Templates`](Templates/) folder is a repository template including clear folder structure, a [README file template](Templates/README.md), [analysis script templates](Templates/scripts/), and more, to help you implement best practices for code sharing in your own coding. 

You can also use `{git}` to only download the `Templates` folder to your machine to get started:
```
# Ask git to clone the CodeStandard repository to your machine 
# but including only the bare essentials (i.e. root README and .gitignore):
git clone --filter=blob:none --sparse https://github.com/SORTEE/CodeStandard.git

# Move into the created folder and download the `Templates` folder from the repository:
cd CodeStandard
git sparse-checkout set Templates/
```


## Citation

If you use this repository, please cite:

- **Paper:** Rodrigues et al. (2026). *A Code Standard for Ecology and Evolution*. Preprint. <https://doi.org/[DOI]>
- **Code:** Rodrigues et al. (2026). *A Code Standard for Ecology and Evolution (version 1)* [Computer software]. Zenodo. <https://doi.org/[DOI]>


## References

- Rodrigues et al. (2026). *A Code Standard for Ecology and Evolution*. Preprint. <https://doi.org/[DOI]>
- van Dis et al. (2023). *Phenological mismatch affects individual fitness and population growth in the winter moth*. Proceedings of the Royal Society B: Biological Sciences, 290(2005), 20230414. <https://doi.org/10.1098/rspb.2023.0414>
