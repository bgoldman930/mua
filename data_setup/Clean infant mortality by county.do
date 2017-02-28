/*
Purpose: Read in raw CDC data and produce infant mortality (averaged over 1999-2015) by county
*/

* Set directories
return clear
do `"`c(sysdir_personal)'profile.do"'
global mua $dropbox/mua
set more off 


project, original("$mua/data/raw_data/covariates/infmort/infmort99to15.txt")
import delimited "$mua/data/raw_data/covariates/infmort/infmort99to15.txt", clear
keep countycode cruderate
drop if countycode==.
replace cruderate="" if cruderate=="Unreliable"
destring cruderate, replace
rename countycode county
save "$mua/data/derived_data/cty_infmort99to15", replace
project, creates("$mua/data/derived_data/cty_infmort99to15.dta")
