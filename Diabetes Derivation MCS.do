/* HARMONISED DIABETES INDICATORS 
   MILLENNIUM COHORT STUDY
   Last updated: 17 July 2024
 */ 


********************************* SETUP ****************************************

* 1. Change input_path to the file that contains all the data for BCS70 (including the COVID-19 survey data) you downloaded from UKDS
global input_path "INPUT YOUR PATH NAME HERE"

* 2. Change working_path to the place you want to store your working files 
global working_path "INPUT YOUR PATH NAME HERE"

* 3. Saving the filepaths to access datasets later
global response "UKDA-8172-stata/stata/stata13/mcs_longitudinal_family_file.dta"
global covid1 "UKDA-8658-stata/stata/stata13/covid-19_wave1_survey_cls.dta"
global covid2 "UKDA-8658-stata/stata/stata13/covid-19_wave2_survey_cls.dta"
global covid3 "UKDA-8658-stata/stata/stata13/covid-19_wave3_survey_cls.dta"

************************** PREPARE LINKAGE SPINE *******************************

use "$input_path/$response", clear 
count 
gen mcsid = MCSID + string(NOCMHH) // temporary ID to aid merging 
keep mcsid 
save "$working_path/MCS_Master.dta", replace

************* EXTRACT AND MERGE ALL RELEVANT DIABETES DATA *********************

* COVID sweep 1 
use "$input_path/$covid1", clear 
tab  CW1_CNUM00, m 
gen mcsid = MCSID + string(CW1_CNUM00) if (CW1_CNUM00 > 0)
keep if mcsid != ""
keep mcsid CW1_LLI_6
gen inCW1 = 1 // create an indicator of response to sweep 
merge 1:1 mcsid using "$working_path/MCS_Master.dta" 
drop if _merge == 1  // only keep people in the response file 
drop _merge  
save "$working_path/MCS_Master.dta", replace

* COVID sweep 2 
use "$input_path/$covid2", clear 
tab CW2_CNUM00, m 
gen mcsid = MCSID + string(CW2_CNUM00) if (CW2_CNUM00 > 0)
keep if mcsid != ""
keep mcsid CW2_LLI1_6 
gen inCW2 = 1 // create an indicator of response to sweep 
merge 1:1 mcsid using "$working_path/MCS_Master.dta" 
drop if _merge == 1  
drop _merge  
save "$working_path/MCS_Master.dta", replace

* COVID sweep 3 

use "$input_path/$covid3", clear 
tab CW3_CNUM00, m 
gen mcsid = MCSID + string(CW3_CNUM00) if (CW3_CNUM00 > 0)
keep if mcsid != ""
keep mcsid CW3_LLI1_6
gen inCW3 = 1 // create an indicator of response to sweep 
merge 1:1 mcsid using "$working_path/MCS_Master.dta" 
drop if _merge == 1 
drop _merge  
save "$working_path/MCS_Master.dta", replace

********************************************************************************
************************ SWEEP-SPECIFIC INDICATORS *****************************
********************************************************************************

use "$working_path/MCS_Master.dta", clear

lab def bin 1 "Yes" 0 "No" .m "DK/refused/not answered"

* COVID Wave 1 
tab CW1_LLI_6, nolab
recode CW1_LLI_6 -8=.m 2=0 
replace CW1_LLI_6 = .m if inCW1 == 1 & CW1_LLI_6 ==. 
replace CW1_LLI_6 =. if inCW1 !=1
rename CW1_LLI_6 diab_20_c1
lab val diab_20_c1 bin
tab diab_20_c1 inCW1, m 

/* COVID W2 needs to be combined with W1 because information is fed forward 
from W1 - so if an individual participated in W1 they are not asked the 
diabetes question again. */ 
tab CW2_LLI1_6, nolab
recode CW2_LLI1_6 -9/-1=.m 2=0
replace CW2_LLI1_6 = .m if inCW2 == 1 & CW2_LLI1_6 ==. 
replace CW2_LLI1_6 =. if inCW2 != 1 
tab CW2_LLI1_6 inCW2, m 
rename CW2_LLI1_6 diab_20_c2 
replace diab_20_c2 = 1 if diab_20_c1 == 1 
replace  diab_20_c2 = 0 if diab_20_c1 == 0 & diab_20_c2 != 1 
tab diab_20_c2 inCW2, m 
replace diab_20_c2 =. if inCW2 != 1 
lab val diab_20_c2 bin 
tab diab_20_c2 inCW2, m 

* COVID Wave 3
recode CW3_LLI1_6 -9/-1=.m 2=0 
lab val CW3_LLI1_6 bin 
rename CW3_LLI1_6 diab_21_c
lab val diab_21_c bin 
tab diab_21_c inCW3, m 

drop inCW* 

* Split up MCSID into cnum and mcsid - as in rest of deposited data 
rename mcsid MCSID 
gen mcsid = ""
gen cnum = ""
replace mcsid = substr(MCSID, 1, strlen(MCSID) - 1)
replace cnum = substr(MCSID, strlen(MCSID), 1)
list MCSID mcsid cnum in 1/10 
destring cnum, replace
tab cnum, m 
drop MCSID

********************************************************************************
*************************** CROSS-SWEEP INDICATORS *****************************
********************************************************************************

/* Work on MCS in this version of the harmonised indicators ends here, since the only
indicators of diabetes available are 'current' diabetes indicators from the 
COVID-19 sweeps. There are questions on longstanding illness, but these need to 
be accessed via the UK Data Service Secure Lab so they aren't included here. */


********************************************************************************
********************** REFORMAT INDICATORS TO DEPOSIT **************************
********************************************************************************

rename (diab_20_c1 diab_20_c2 diab_21_c) (diab_20_current1 diab_20_current2 diab_21_current)

lab var mcsid "MCS Research ID - Anonymised Family/Household Identifier"
lab var cnum "Cohort member number in MCS household"
lab var diab_20_current1 "Currently has diabetes age 20 [COVID survey 1]" 
lab var diab_20_current2 "Currently has diabetes age 20 [COVID survey 2]" 
lab var diab_21_current "Currently has diabetes age 21 [COVID survey 3]" 

lab define depositlab1 1 "Diabetes reported in sweep" ///
					   2 "No diabetes reported in sweep" ///
					   -1 "No information provided" ///
					   -9 "Not in sweep"
foreach var in diab_20_current1 diab_20_current2 diab_21_current {   	
	recode `var' 0=2 .m=-1 .=-9			
	lab val `var' depositlab1 			
}

order mcsid cnum diab_20_current1 diab_20_current2 diab_21_current

save "$working_path/MCS_Derived.dta", replace
