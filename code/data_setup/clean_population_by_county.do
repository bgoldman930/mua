/***
Purpose: Create county population statistics
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


*Read in raw census data
project, original ("${root}/data/raw/county_population.dta")
use "${root}/data/raw/county_population.dta", clear

collapse (mean) pop*, by(fips)
g county = real(fips)
drop fips
order county pop*
keep county pop*
drop pop19904 pop20104 
save "${root}/data/derived/cty_pop", replace
project, creates("${root}/data/derived/cty_pop.dta")
