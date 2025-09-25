/* HARMONISED DIABETES INDICATORS 
   NEXT STEPS (FORMERLY THE LONGITUDINAL STUDY OF YOUNG PEOPLE IN ENGLAND)
   Last updated: 17 July 2024
 */ 

********************************************************************************
********************************* SETUP ****************************************

* 1. Change input_path to the file that contains all the data for BCS70 (including the COVID-19 survey data) you downloaded from UKDS
global input_path "INPUT YOUR PATH NAME HERE"

* 2. Change working_path to the place you want to store your working files 
global working_path "INPUT YOUR PATH NAME HERE"

* 3. Saving the filepaths to access datasets later
global response "UKDA-5545-stata\stata\stata13\eul\next_steps_longitudinal_file.dta"
global covid1 "UKDA-8658-stata/stata/stata13/covid-19_wave1_survey_cls.dta"
global covid2 "UKDA-8658-stata/stata/stata13/covid-19_wave2_survey_cls.dta"
global covid3 "UKDA-8658-stata/stata/stata13/covid-19_wave3_survey_cls.dta"


************************** PREPARE LINKAGE SPINE *******************************

* We want to create a list of all IDs appearing in Next Steps 
 
use "$input_path/$response", clear // cohort members at study start
keep NSID 
rename NSID nsid
save "$working_path/NS_Master.dta", replace

count

************* EXTRACT AND MERGE ALL RELEVANT DIABETES DATA *********************

* COVID Sweep 1 
use "$input_path/$covid1", clear 
keep if NSID != ""
keep NSID CW1_LLI_6
rename NSID nsid 
gen inCW1 = 1 
merge 1:1 nsid using "$working_path/NS_Master.dta" 
drop if _merge == 1  // only keep people in "response file"
drop _merge  
save "$working_path/NS_Master.dta", replace

* COVID Sweep 2 
use "$input_path/$covid2", clear 
keep NSID CW2_LLI1_6
keep if NSID != ""
rename NSID nsid  
gen inCW2 = 1 
merge 1:1 nsid using "$working_path/NS_Master.dta" 
drop if _merge == 1 
drop _merge  
save "$working_path/NS_Master.dta", replace

* COVID Sweep 3 
use "$input_path/$covid3", clear 
keep NSID CW3_LLI1_6
keep if NSID != ""
rename NSID nsid 
gen inCW3 = 1 
merge 1:1 nsid using "$working_path/NS_Master.dta" 
drop if _merge == 1 
drop _merge  
save "$working_path/NS_Master.dta", replace

drop inCW*

********************************************************************************
************************ SWEEP-SPECIFIC INDICATORS *****************************
********************************************************************************

use "$working_path/NS_Master.dta", clear

lab def bin 1 "Yes" 0 "No" .m "DK/refused/not answered"

* COVID Waves 1 
tab CW1_LLI_6, nolab
recode CW1_LLI_6 -8=.m 2=0 
replace CW1_LLI_6 = .m if inCW1 == 1 & CW1_LLI_6 ==. 
replace CW1_LLI_6 = . if inCW1 !=1 
rename CW1_LLI_6 diab_30_c1
lab val diab_30_c1 bin
tab diab_30_c1 inCW1, m 

/* COVID W2 needs to be combined with W1 because information is fed forward 
from W1 - so if an individual participated in W1 they are not asked the 
diabetes question again. */ 
tab CW2_LLI1_6, nolab
recode CW2_LLI1_6 -9/-1=.m 2=0
replace CW2_LLI1_6  =. if inCW2 != 1 
rename CW2_LLI1_6 diab_30_c2
replace diab_30_c2 = 1 if diab_30_c1 == 1 
replace diab_30_c2 = 0 if diab_30_c1 == 0  
tab diab_30_c2 inCW2,m 
replace diab_30_c2 =. if inCW2 != 1 
lab val diab_30_c2 bin 

* COVID Wave 3
recode CW3_LLI1_6 -9/-1=.m 2=0 
lab val CW3_LLI1_6 bin 
rename CW3_LLI1_6 diab_31_c
lab val diab_31_c bin 
tab diab_31_c inCW3, m 

drop inCW* 

********************************************************************************
*************************** CROSS-SWEEP INDICATORS *****************************
********************************************************************************

/* Work on Next Steps in this version of the harmonised indicators ends here,
since the only indicators of diabetes available are 'current' diabetes indicators 
from the COVID-19 sweeps. */

 
********************************************************************************
********************** REFORMAT INDICATORS TO DEPOSIT **************************
********************************************************************************

rename (diab_30_c1 diab_30_c2 diab_31_c) (diab_30_current1 diab_30_current2 diab_31_current)

lab var nsid "NSID - Cohort Member Identifier"
lab var diab_30_current1 "Currently has diabetes age 30 [COVID survey 1]" 
lab var diab_30_current2 "Currently has diabetes age 30 [COVID survey 2]" 
lab var diab_31_current "Currently has diabetes age 31 [COVID survey 3]" 

lab define depositlab1 1 "Diabetes reported in sweep" ///
					   2 "No diabetes reported in sweep" ///
					   -1 "No information provided" ///
					   -9 "Not in sweep"
foreach var in diab_30_current1 diab_30_current2 diab_31_current {   	
	recode `var' 0=2 .m=-1 .=-9			
	lab val `var' depositlab1 			
}

order nsid diab_30_current1 diab_30_current2 diab_31_current

save "$working_path/NS_Derived.dta", replace
