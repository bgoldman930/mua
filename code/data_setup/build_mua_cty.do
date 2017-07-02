/***
Purpose: Output a dataset of county level MUAs
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


*---------------------------------------------------------------------
*Read in raw MUA data and keep only county level designations
*---------------------------------------------------------------------

project, uses("${root}/data/derived/mua.dta")
use "${root}/data/derived/mua.dta", clear

*Keep only geographic level designnations, assignments at county level, 
*	and designations (dropping withdrawls but leaving pending)
keep if 	(designationtypecode == "MUA" | ///
			designationtypecode == "MUA-GE") & ///
			(muapstatuscode == "D" | ///
			muapstatuscode == "P") & ///
			geo_type == "SCTY"

*For small number of duplicates, keep first designation 
bysort county (date): keep if _n == 1

*Merge on zcta5 - capture all zcta5 in counties
*1:m merge as a single zcta5 can be in multiple counties, store population
*	variables to make a later cut if necessary
project, uses("${root}/data/derived/zcta_county_rel_10.dta") preserve 
merge 1:m county using "${root}/data/derived/zcta_county_rel_10.dta", ///
	keepusing(zcta5 zpop zpoppct copop copoppct) keep(1 3) nogen
rename (copop copoppct) (basepop basepoppct)

*For zcta5's associated with multiple counties, keep county that holds the 
*	highest share of that zcta's population
bysort zcta5 (zpoppct): keep if _n==_N
drop if mi(zcta5)

*Keep necessary variables and clean
keep zcta5 date year month day zpop zpoppct basepop basepoppct
order zcta5 date year month day zpop zpoppct basepop basepoppct
sort date zpop
g desig_level = "cty"

*Output data
save "${root}/data/derived/mua_cty.dta", replace
project, creates("${root}/data/derived/mua_cty.dta")
