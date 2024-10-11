# CodeStandard

This is a colaborative repository for the **Hackathon SORTEE's Code Club Hackathon: Creating a Code Standard**. The hackathon take place online on Wed Oct 16 2024, 06:00-07:55 UTC +00:00 for the Society for Open, Reproducible and Transparent Ecology & Evolution (SORTEE). Here you find all the relevant files and links for other resources used during the hackathon. This repository is your landing page along the Hackathon. Please bookmark this repository for easy access to all resources.

Before the hackathon, make sure you have a github account. 

## Useful links

1. [HackMD](https://hackmd.io/kxNotAiRQdaIq62pkQ2K_A) - Here we have a markdown editor designed for real-time writing and collaboration that will be used as a notebook during the Hackathon. There you can find more detailed information about the Hackathon, especlially in the [Hackathon Outline](https://hackmd.io/kxNotAiRQdaIq62pkQ2K_A#Hackathon-outline) section. 
2. [Slides](https://docs.google.com/presentation/d/1fSY_UCjT8Wz---Ultba62r_sItDC2qKkmnwcY78LEuY/edit?usp=sharing). The slides used in the Hackathon are already available. 
3. [List of Participants](https://docs.google.com/spreadsheets/d/1U3LnAbkklFMbEmkUIWbzjq7RAtb_xPedyc2VvixNRDE/edit?usp=sharing). We will ask participants to fill their informantion during the Hackathon. 
4. [Data repository](https://datadryad.org/stash/dataset/doi:10.5061/dryad.m905qfv5p) - You'll only need to download the files 'CatFood2021_deposit.csv' and 'README.md' from the data repository.
5. [Paper](https://royalsocietypublishing.org/doi/10.1098/rspb.2023.0414) van Dis et al 2023. Phenological mismatch affects individual fitness and population growth in the winter moth. https://royalsocietypublishing.org/doi/10.1098/rspb.2023.0414

## How to work in the repository

Clone the repository to your computer by creating an R project or by using the git command bellow: 

`git clone https://github.com/SORTEE/CodeStandard.git` 

### Important :exclamation::exclamation::exclamation: 

After clone the repository, switch to the `hackathon` branch. You will not be allowed to push changes to the `main` branch.     

Command: `git switch hackathon` or `git checkout hackathon` if you have an older version of git installed.   
Then, make sure you are in the right place: `git branch`  

## Repository structure

The repository has six folders with the same internal structure. Each folder will be used by one of the working groups during the hackathon. 

├── :open_file_folder:01_Reported  
├── :open_file_folder:02_Run  
├── :open_file_folder:03_Reliable  
├── :open_file_folder:04_Reproducible  
├── :open_file_folder:05_Organization_Structure  
├── :open_file_folder:06_Other_considerations   
├── :page_facing_up:LICENSE  
└── :page_facing_up:README.md  

In each folder we provide the same innitial code to be reviewed and modified in the Hackathon. The idea is that from the same innitial code we will have different outputs of code. So after the hackathon we can go trough the modifications and unify it in a single code/folder. 

## Good pratices for colaboration in github

We are colaborating in git/github to allow multiple people to edit code and colaborate in the same project. We assume that the participants has basic knowledge and experience with git/github. 

Since we are several people in the same repo at the same time, we need to avoid have conflicts of code. 

We suggest that: 

- Avoid work in the same file at the same time. Discuss within your group the tasks before work in a particular file. Let people know that you are working there. 
- Commmit and push often. Always pull before push your commits. 
- You can come across to merging messages (especially if you are using command line to pull/push). If so, accept the merging. It depends, on the editor configured on your git, but helpful commands can be `:wq` (write and quite) or `ctrl/cmd + x`.
- If you need to solve a conflict, make sure you can resolve it before commit. If you are unsure, discuss with your group or call the hosts before change and commit the file. 
- If you get stucked using git locally in your machine, you can edit files directly on github and add the changes you made as a commit. If you choose to do like that, make sure you are in the `hackathon` branch.

