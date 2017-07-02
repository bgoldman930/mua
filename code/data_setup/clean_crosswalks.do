/***
Purpose: Clean crosswalks to ensure suitability for merges
***/

* Set directories
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mua}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mua}/code/set_environment.do"
}
set more off 


*county-zcta5
project, original("${root}/data/raw/zcta_county_rel_10.txt")
import delimited "${root}/data/raw/zcta_county_rel_10.txt", clear 

rename county cfips
rename geoid county

save "${root}/data/derived/zcta_county_rel_10.dta", replace
project, creates("${root}/data/derived/zcta_county_rel_10.dta") 

*mcd-zcta5
project, original("${root}/data/raw/zcta_cousub_rel_10.txt")
import delimited "${root}/data/raw/zcta_cousub_rel_10.txt", clear 

rename geoid mcd

save "${root}/data/derived/zcta_cousub_rel_10.dta", replace
project, creates("${root}/data/derived/zcta_cousub_rel_10.dta") 

*census tract-zcta5
project, original("${root}/data/raw/zcta_tract_rel_10.txt")
import delimited "${root}/data/raw/zcta_tract_rel_10.txt", clear 

save "${root}/data/derived/zcta_tract_rel_10.dta", replace
project, creates("${root}/data/derived/zcta_tract_rel_10.dta") 
