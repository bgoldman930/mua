/*
Purpose: Create designation year X mo dataset for MUAs and HPSAs
*/

* Set directories
return clear
do `"`c(sysdir_personal)'profile.do"'
global mua $dropbox/mua
set more off 


* I. CREATE DESIGNATION YEAR X MO DATASET FOR MUAs
** one row per MUA
** note this dataset contains both MUAs and MUPs; can drop MUPs later if necessary
project, original("$mua/data/raw_data/mua/MUA_DET.csv")
insheet using "$mua/data/raw_data/mua/MUA_DET.csv", comma clear
gen year=substr(v53,1,4)
destring year, replace
gen month=substr(v53,6,2)
destring month, replace
order year month
sort year month

* Note an MUA can be a
** minor civil division (MCD)
** state county (SCTY) - the majority
** census tract (CT)
* Organize all three geocodes:
rename v55 geo_type
rename minorcivildivisionfipscode mcd
rename commonstatecountyfipscode county
rename censustract ct
sort year month geo_type
order year month geo_type mcd county ct
save "$mua/data/derived_data/mua", replace
project, creates("$mua/data/derived_data/mua.dta")

