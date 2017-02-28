/***
Purpose: Create county population statistics
***/

* Set directories
return clear
do `"`c(sysdir_personal)'profile.do"'
global mua $dropbox/mua
set more off 

*Read in raw census data
project, original ("$mua/data/raw_data/census/county_population.dta")
use "$mua/data/raw_data/census/county_population.dta", clear

collapse (mean) pop*, by(fips)
g county = real(fips)
drop fips
order county pop*
keep county pop*
drop pop19904 pop20104 
save "$mua/data/derived_data/cty_pop", replace
project, creates("$mua/data/derived_data/cty_pop.dta")
