/***
Purpose: Output a dataset of census tract level MUAs
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
*Read in raw MUA data and keep only census tract level designations
*---------------------------------------------------------------------

project, uses("${root}/data/derived/mua.dta")
use "${root}/data/derived/mua.dta", clear

*Keep only geographic level designnations, assignments at county level, 
*	and designations (dropping withdrawls but leaving pending)
keep if 	(designationtypecode == "MUA" | ///
			designationtypecode == "MUA-GE") & ///
			(muapstatuscode == "D" | ///
			muapstatuscode == "P") & ///
			geo_type == "CT"

*Generate geographic identifiers

*State
gen str2 st = string(statefipscode, "%02.0f")

*County (remove states from variable)
g str5 cfips = string(county, "%05.0f")
g cty = substr(cfips,3,3)

*Census tracts
split ct, parse(".")
g tract = ct1+ct2

g geoid = st+cty+tract
destring geoid, replace

*For small number of duplicates, keep first designation 
bysort geoid (date): keep if _n == 1

*Merge on zcta5 - capture all zcta5 overlapping a given census tract
*1:m merge as a single zcta5 can be in multiple census tracts, store population
*	variables to make a later cut if necessary
project, uses("${root}/data/derived/zcta_tract_rel_10.dta") preserve 
merge 1:m geoid using "${root}/data/derived/zcta_tract_rel_10.dta", ///
	keepusing(zcta5 zpop zpoppct trpop trpoppct) keep(1 3) nogen
rename (trpop trpoppct) (basepop basepoppct)

*For zcta5's associated with multiple tracts, keep tract that
*	holds the highest share of that zcta's population
bysort zcta5 (zpoppct): keep if _n==_N
drop if mi(zcta5)

*Keep necessary variables and clean
keep zcta5 date year month day ///
	zpop zpoppct basepop basepoppct
order zcta5 date year month day ///
	zpop zpoppct basepop basepoppct
sort date zpop
g desig_level = "ct"

*Output data
save "${root}/data/derived/mua_ct.dta", replace
project, creates("${root}/data/derived/mua_ct.dta")
