# CodeStandard

This is the collaborative repository for the **SORTEE Code Club Hackathon: Creating a Code Standard**, writing the "perfect" Open, Reliable, and Transparent (ORT) code for Ecology & Evolution.

The Hackathon takes place online on _Wed Oct 16 2024, 06:00-07:55 UTC +00:00_ as part of [the 2024 SORTEE Conference](https://www.sortee.org/upcoming/): the Society for Open, Reliable, and Transparent Ecology & Evolution. In this repo you can find all the relevant instructions, files and links to other resources used during the hackathon. 

❗ **This repository is your landing page for the Hackathon. Please bookmark this repo for easy access to all resources.**

Before the Hackathon, make sure you have a Github account. 

🙋 **Hackathon hosts:** Natalie E. van Dis & Arthur V. Rodrigues
🧑‍🤝‍🧑 **Hackathon participants:** Kevin R. Bairos-Novak, Mattia Ghilardi, Alfredo Sánchez-Tójar, Kelleher Saoirse

## Hackathon links

1. [HackMD](https://hackmd.io/kxNotAiRQdaIq62pkQ2K_A) -- Collaborative Markdown file for real-time writing that we will use as a notebook during the Hackathon. Here you can find more detailed information about the Hackathon.

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; :page_facing_up: Please carefully read section [Hackathon Outline](https://hackmd.io/kxNotAiRQdaIq62pkQ2K_A#Hackathon-outline) describing how we will work. 

2. [Slides](https://docs.google.com/presentation/d/1fSY_UCjT8Wz---Ultba62r_sItDC2qKkmnwcY78LEuY/edit?usp=sharing) -- The slides with the introduction, instructions, and schedule for the Hackathon are available here. 
3. [Participant sign-up sheet](https://docs.google.com/spreadsheets/d/1U3LnAbkklFMbEmkUIWbzjq7RAtb_xPedyc2VvixNRDE/edit?usp=sharing) -- We will ask participants to sign-up during the Hackathon and fill in their information to be added to the team of this repo and be listed as contributor to the Code Standard. 
4. [Paper](https://royalsocietypublishing.org/doi/10.1098/rspb.2023.0414) -- To create the Code Standard, we will work on the code from this paper: _van Dis et al 2023. Phenological mismatch affects individual fitness and population growth in the winter moth. Proc R Soc B 290: 20230414._
5. [Data repository](https://datadryad.org/stash/dataset/doi:10.5061/dryad.m905qfv5p) -- For the Hackathon, you will only need to download the files ```CatFood2021_deposit.csv``` and ```README.md``` from the data repository.

## How to work in the repository

Clone the repository to your computer by creating an R project or by using the `git` command bellow: 

`git clone https://github.com/SORTEE/CodeStandard.git` 

### ❗ Important

After cloning the repository, switch to the `hackathon` branch. You will not be allowed to push changes to the `main` branch.     

Command: `git switch hackathon` or if you have an older version of git installed: `git checkout hackathon`    
Check that you are in the right place with command: `git branch`  

## Repository structure

The repository has six folders with the same internal structure and files. Each folder will be used by one of the working groups during the Hackathon: 

├── :open_file_folder:01_Reported  
├── :open_file_folder:02_Run  
├── :open_file_folder:03_Reliable  
├── :open_file_folder:04_Reproducible  
├── :open_file_folder:05_Organization_Structure  
├── :open_file_folder:06_Other_considerations   
├── :page_facing_up:LICENSE  
└── :page_facing_up:README.md  

In each folder, we provide the same initial files to be reviewed and modified in the Hackathon. 

The idea is that from the same initial code we will have six different final code versions, focusing on different goals. This way, each code version shows the ORT steps implemented when focusing on a particular goal (e.g. goal Group 1: Make sure the code perfectly matches the methods of the paper). **After the Hackathon, these six different versions will be united into one single code/folder to make up the Code Standard.**

## Good practices for collaboration in Github

We are collaborating using `git` and Github to allow multiple people to edit the code while working in the same project folder. We assume that the participants have basic knowledge and experience with `git` and Github. 

Since we are several people in the same repo at the same time, we need to avoid `git` conflicts. 

We suggest to: 

- Avoid working in the same file at the same time. Communicate! Discuss within your group the task division before starting to work in a particular file. Let people know that you are working there. 
- `commmit` and `push` often (i.e. for every task/major change). Always `pull` before pushing your commits. 
- You can come across merging messages (especially if you are using the command line to ```pull/push```). If so, accept the merging. It depends on the editor configured on your `git`, but helpful commands can be `:wq` (write and quite) or `ctrl/cmd + x`.
- If you have a `git` conflict, you need to resolve it before committing. If you are unsure how to, discuss with your group or ask the Hackathon hosts for help before changing and committing the file. 
- If you get stuck using `git` locally in your machine, you can edit files directly on Github and add the changes you made as a commit. Also here: make sure you are working in the `hackathon` branch.
- We have a `git` help section at the end on the slides. Check there: [Hackathon Slides](https://docs.google.com/presentation/d/1fSY_UCjT8Wz---Ultba62r_sItDC2qKkmnwcY78LEuY/edit?usp=sharing).

