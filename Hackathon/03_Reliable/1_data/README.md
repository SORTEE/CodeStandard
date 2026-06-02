# Raw data belonging to the manuscript "Phenological mismatch affects individual fitness and population growth in the winter moth"

## Download
You can download the data from Dryad repository: https://doi.org/10.5061/dryad.m905qfv5p


## Study
We know little about the fine-scale fitness consequences of phenological mismatch at the individual level and how this mismatch affects population dynamics in the winter moth. 
To determine the fitness consequences of mistimed egg hatching relative to timing of oak budburst, we quantified survival and pupation weight in a feeding experiment. 
We then investigated whether these individual fitness consequences have population-level impacts by estimating the effect of phenological mismatch on population dynamics, using our long-term data (1994-2021) on relative winter moth population densities at four locations in the Netherlands. 


## Methods
Field data on winter moths were collected yearly since 1994 in four forests around Arnhem, the Netherlands, using simple funnel traps to catch adult moths in winter (see [Van Asch et al. 2013, Nat Clim Change (3)] for details). 
Eggs collected from these wild adults were kept in a field shed at the Netherlands Institute of Ecology. 
Deposited field data for the period 1994-2021 include per year: number of adult moths collected, with for each moth (individual-based data with individual identifier): number of eggs laid, spring seasonal timing of their eggs kept in our field shed, and spring seasonal timing of budburst of oak trees in the field on which adults were caught.

Experimental data were collected in a caterpillar feeding experiment in the Spring of 2021, using eggs from the long-term field monitoring (described above). 
The experiment consisted of a split-brood design, where the timing of hatching of eggs laid by each female was manipulated to induce staggered hatching. 
Caterpillars were then divided over different photoperiod treatments (constant photoperiod or naturally changing photoperiod) and different phenological mismatch treatments (hatching before [0-4 days] or after oak budburst [1-5 days], and then fed with oak leaves accordingly). 
Deposited experimental data include per caterpillar (individual-based data with individual identifier): parent origin (Catch area, tree, and date), hatch date, death date (if died before pupating), pupation date, pupation weight, date of adult emerging, adult weight, and adult sex.


## Description of the data and file structure
All data files are linked through the individual identifiers described below (i.e. TubeID, ClutchID, CaterpillarID).

--- Field data files
**NB: YearCatch = November/December when adult moths are caught, YearHatch = YearCatch+1 i.e. first Spring following catching period in the previous year**

<1994-2021_Field_nr-traps_deposit.csv> 
Contains the number of funnel traps placed for each forest and each year of data (AreaShortName: DO=Doorwerth, HV=Hoge Veluwe, OH=Oosterhout, WA=Warnsborn)

<1994-2021_Field_PopNum_raw_deposit.csv> 
Contains for each forest and each year of data, the number of adult winter moth females (NoFemale) and males (NoMale) per catch date in NovemberDays i.e. julian dates with origin YEARCATCH-10-31 (NovemberDate) on each tree (identified by the combination of Site and Tree numbers)

<1994-2021_Field_timing_deposit.csv> 
Contains for each forest and each year, catch information for each female [identifier=TubeID] incl. the tree species and timing of budburst of that tree in the following Spring in AprilDays i.e. julian dates with origin YEARHATCH-03-31 (MinOfAprilDate), as well as the hatching date of her egg clutche(s) (identifier=ClutchID) calculated as the date on which 50% of the eggs had hatched in AprilDays (D50Calc). The measure of phenological mismatch is then calculated as: Mismatch = D50Calc - MinOfAprilDate

<1994-2021_Field_Eggs_deposit.csv> 
Contains for each forest and each year and each female (i.e. TubeID) the number of eggs she laid.


--- Experimental data files
**NB: Treatment names consist of photoperiod treatment: Changing [Chang] or Constant [Const]; and phenological mismatch treatment: Day[-4,5]**

<CatFood2021_deposit.csv> 
Contains all experimental data collected from the caterpillar feeding experiment (CatFoodExp2021), incl. for each Caterpillar (identifier=CaterpillarID) their origin (ClutchID -> TubeID incl. catch info for the female parent), the treatment the caterpillar was assigned to, when the caterpillar hatched in April Days i.e. julian dates with origin 2021-03-31 (HatchAprilDay), death date in April days if applicable (DeadAprilDay), the pupation date in April days if applicable (PupationAprilDay), weight at pupation in grams (PupaWeight), the date of adult emergence in November days i.e. julian dates with origin 2021-10-31 if applicable (AdultNovDate), adult weight (in grams) and adult sex.


## Code/Software
All code needed to reproduce the manuscript's analysis of field data and experimental data using R are included. Environment files <env_*.txt> indicate required software.
All code is annotated and can also be accessed on GitHub: https://github.com/NEvanDis/WM_fitness
