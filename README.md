# A Code Standard for Ecology and Evolution

**Authors: Arthur V. Rodrigues, Cecilia Baldoni, Mattia Ghilardi, Saoirse Kelleher, Abhishek Kumar, Martin Luquet, Charlotte Recapet, Kevin R. Bairos-Novak, Giulia Masoero, Matthieu Paquet, Alfredo Sánchez-Tójar, Saeed Shafiei Sabet, Gabe Winter & Natalie E. van Dis.**

The code standard is a piece of R code with accompanying metadata files that can be used as an accessible and easy way to implement transparent and reproducible practices in your own coding by example. To enable easy implementation of Open, Reliable, and Transparent (ORT) best practices for code sharing, we also offer a repository template for reuse.

This work was created by members of the Society for Open, Reliable, and Transparent Ecology and Evolution (SORTEE), after reviewing a existing code coming from a published paper and discussing good code sharing practices in Ecology and Evolution (See details in Rodrigues et al. 2026) . Here, you find the Code Standard, Templates for easy implementation and the structure of the Hackathon that we designed to produce this code standard.

We ranked the Top 10 Open, Reliable and Transparent (ORT) practices for code sharing in Ecology and Evolution (Rodrigues et al. 2026).

|  |  |  |
|------------------------|------------------------|------------------------|
| **Rank** | **Topic** | **ORT practice** |
| 1 | Reported | Ensure that shared code matches methods description in the paper |
| 2 | Reported, Reproducible | Record and report required softwares, packages and their versions |
| 3 | Organisation & Structure | Have code with a clear structure |
| 4 | Organisation & Structure | Use an appropriate folder structure for your project |
| 5 | Reported, Reliable, Organisation & Structure | Extensively comment your scripts |
| 6 | Other | Provide clear and complete documentation (i.e. README and metadata) |
| 7 | Run | Ensure that your code runs without error and mistakes |
| 8 | Other | Ensure that data and code adhere to the FAIR principles: Findable, Accessible, Interoperable and Reusable |
| 9 | Run | Use R package namespaces for essential functions and function names that overlap between packages. (e.g. `lme4::glmer()`) |
| 10 | Reproducible | Ensure that the whole analysis workflow is code-based and self-contained |

## How to use this repository

This repository has three folders, with its respective README files:

```         
  |- CodeStandard
  |- Hackathon
  |- Templates
```

In `CodeStandard` you will find the example code and support documentation implementating Open, Reliable and Transparent (ORT) best practices for code sharing.

For this practical example, we chose a relatively simple and common ecology and evolution analysis. The analysis script construct a fitness curve from experimental data and is part of a published paper (van Dis et al. 2023). As such, it offers all basic steps in an analysis workflow: loading required packages, exploring the data, data preparation, fitting a model, summarizing results and creating visualization outputs. In addition to the analysis script, the `CodeStandard` implement best practices for code support documentation, in reproducibility, ensuring correct package versions via `{renv}`, and repository organization and structuring. **The `CodeStandard` repository is intended to serve as a reference for good practice in code sharing**. It can be your home base for code sharing. The place where you return to see how you could implement an ORT good practice.

To facilitate the implementation of this best practices you can use `Templates` folder. There you will find a template structure for the repository, with template README file and template script.

Finally, we also share the structure that help us to review and implement this code standard. In the folder `Hackathon`, you find the base code, the separation in topics for code review, and the auxiliary documentation used for the Hackathon. We share this to ensure transparency in the production of the Code Standard, as well as it may serve as a reference for groups that want to implement a Code Standard that best fit they current analysis workflow.

## Citation

If you use this repository, please cite:

- **Article:** Rodrigues et al. (2026). *A Code Standard for Ecology and Evolution*. Journal. [https://doi.org/[DOI]](https://doi.org/%5BDOI%5D){.uri}
- **Code:** Author(s). (Year). *Repository title* [Computer software]. Code Repository. [https://doi.org/[DOI]](https://doi.org/%5BDOI%5D){.uri}

## References

Rodrigues et al. (2026s). *A Code Standard for Ecology and Evolution*. Journal. [https://doi.org/[DOI]](https://doi.org/%5BDOI%5D){.uri}

van Dis et al. (2023). *Phenological mismatch affects individual fitness and population growth in the winter moth*. Proceedings of the Royal Society B: Biological Sciences, 290(2005), 20230414. <https://doi.org/10.1098/rspb.2023.0414>
