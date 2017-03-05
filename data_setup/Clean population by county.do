/***
Purpose: Create county population statistics
***/

* Set directories
return clear
do `"`c(sysdir_personal)'profile.do"'
capture project, doinfo
global root `r(pdir)'
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
