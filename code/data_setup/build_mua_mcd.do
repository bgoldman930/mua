/***
Purpose: Output a dataset of county subdivision level MUAs
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
*Read in raw MUA data and keep only minor civil division designations
*---------------------------------------------------------------------

project, uses("${root}/data/derived/mua.dta")
use "${root}/data/derived/mua.dta", clear

*Keep only geographic level designnations, assignments at county level, 
*	and designations (dropping withdrawls but leaving pending)
keep if 	(designationtypecode == "MUA" | ///
			designationtypecode == "MUA-GE") & ///
			(muapstatuscode == "D" | ///
			muapstatuscode == "P") & ///
			geo_type == "MCD"

*For small number of duplicates, keep first designation 
bysort mcd (date): keep if _n == 1

*Merge on zcta5 - capture all zcta5 in county subdivisions
*1:m merge as a single zcta5 can be in multiple subdivisions, store population
*	variables to make a later cut if necessary
project, uses("${root}/data/derived/zcta_cousub_rel_10.dta") preserve 
merge 1:m mcd using "${root}/data/derived/zcta_cousub_rel_10.dta", ///
	keepusing(zcta5 zpop zpoppct cspop cspoppct) keep(1 3) nogen
rename (cspop cspoppct) (basepop basepoppct)

*For zcta5's associated with multiple county subdivisions, keep county sub that
*	holds the highest share of that zcta's population
bysort zcta5 (zpoppct): keep if _n==_N
drop if mi(zcta5)

*Keep necessary variables and clean
keep zcta5 date year month day ///
	zpop zpoppct basepop basepoppct
order zcta5 date year month day ///
	zpop zpoppct basepop basepoppct
sort date zpop
g desig_level = "mcd"

*Output data
save "${root}/data/derived/mua_mcd.dta", replace
project, creates("${root}/data/derived/mua_mcd.dta")
