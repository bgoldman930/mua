/***
Purpose: Clean county population data
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
*Read in already clean NBER file
*---------------------------------------------------------------------

project, original("${root}/data/raw/county_population.dta")
use "${root}/data/raw/county_population.dta", clear

*Clean county fips code
g state=substr(fips, 1, 2)
g county=substr(fips, 3, 5)
destring state county, replace

*Drop decennial census measures
drop pop20104 base20104 pop19904

*Many counties have their data spread across two rows - fix this
collapse (firstnm) region state_name county_name pop*, by(state county)

*Clean and output
rename pop* pop_*
keep state county region state_name county_name pop_*
order state county region state_name county_name pop_*
sort state county
compress
save "${root}/data/covariates/county_population.dta", replace
project, creates("${root}/data/covariates/county_population.dta")
 
