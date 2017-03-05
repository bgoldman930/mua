/*
Purpose: Read in raw CDC data and produce infant mortality (averaged over 1999-2015) by county
*/

* Set directories
return clear
do `"`c(sysdir_personal)'profile.do"'
capture project, doinfo
global root `r(pdir)'
set more off 


project, original("${root}/data/raw/infmort99to15.txt")
import delimited "${root}/data/raw/infmort99to15.txt", clear
keep countycode cruderate
drop if countycode==.
replace cruderate="" if cruderate=="Unreliable"
destring cruderate, replace
rename countycode county
save "${root}/data/derived/cty_infmort99to15", replace
project, creates("${root}/data/derived/cty_infmort99to15.dta")
