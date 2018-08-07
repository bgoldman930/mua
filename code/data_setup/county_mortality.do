/***
Purpose: Build a penl of county level mortality rates
***/

*---------------------------------------------------------------------
*Read in raw CDC wonder data
*---------------------------------------------------------------------

import delimited "${root}/data/raw/Compressed Full Mortality 1968-1978.txt", clear 
tempfile 1
save `1'

import delimited "${root}/data/raw/Compressed Full Mortality 1979-1998.txt", clear 
destring deaths population cruderatestandarderror ageadjustedratestandarderror, replace force
tempfile 2
save `2'

*Append together
*Force because of cruderate containing characters - don't need this variable
clear
append using `1'
append using `2'

*---------------------------------------------------------------------
*Clean the by year data
*---------------------------------------------------------------------

*Make clean county and state variables
rename county countyname
tostring countycode, replace format(%05.0f) 
g state=substr(countycode, 1, 2)
g county=substr(countycode, 3, 5)
destring state county, replace

*Drop pooled total rows and the notes rows
drop if mi(year)

*Get rid of the text strings in the rate variables
foreach v in cruderate ageadjustedrate {
	split `v', parse(" (")
	drop `v'
	destring `v'*, replace
	rename `v'1 `v'
	replace `v'=`v'2 if mi(`v')
	drop `v'2
	destring `v', replace force
}

*Clean
keep state county year population deaths cruderate cruderatestandarderror ageadjustedrate ageadjustedratestandarderror
order state county year population deaths cruderate cruderatestandarderror ageadjustedrate ageadjustedratestandarderror

*Output
compress
save "${root}/data/covariates/county_mort.dta", replace
