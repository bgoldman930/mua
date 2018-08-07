/***
Purpose: Build infant mortality rates at the county level
***/

*---------------------------------------------------------------------
*Read in raw CDC wonder data
*---------------------------------------------------------------------

import delimited "${root}/data/raw/Compressed Mortality 1968-1978.txt", clear 
tempfile 1
save `1'

import delimited "${root}/data/raw/Compressed Mortality 1979-1998.txt", clear 
tempfile 2
save `2'

import delimited "${root}/data/raw/Compressed Mortality 1999-2016.txt", clear 
tempfile 3
save `3'

import delimited "${root}/data/raw/Pooled Mortality 1968-1978.txt", clear 
drop if mi(countycode)
tempfile 4 
save `4'

import delimited "${root}/data/raw/Pooled Mortality 1979-1998.txt", clear 
drop if mi(countycode)
tempfile 5
save `5'

import delimited "${root}/data/raw/Pooled Mortality 1999-2016.txt", clear 
drop if mi(countycode)
tempfile 6
save `6'

*Append together
*Force because of cruderate containing characters - don't need this variable
clear
use `1', clear
append using `2', force
append using `3', force

*---------------------------------------------------------------------
*Clean the by year data
*---------------------------------------------------------------------

*Append together
*Force because of cruderate containing characters - don't need this variable
clear
use `1', clear
append using `2', force
append using `3', force

*Make clean county and state variables
rename county countyname
tostring countycode, replace format(%05.0f) 
g state=substr(countycode, 1, 2)
g county=substr(countycode, 3, 5)
destring state county, replace

*Drop pooled total rows
drop if mi(year)

*Clean
keep state county year population deaths
order state county year population deaths
g inf_mort=deaths/population
rename population births
tempfile by_year
save `by_year'

*---------------------------------------------------------------------
*Clean the grouped year data
*---------------------------------------------------------------------

*Start with 1968-78 data
use `4', clear
rename (deaths population) (deaths_1968_1978 births_1968_1978)
g inf_mort_1968_1978=deaths_1968_1978/births_1968_1978

*Merge on other files
merge 1:1 countycode using `5', nogen keepusing(deaths population)
rename (deaths population) (deaths_1979_1998 births_1979_1998)
g inf_mort_1979_1998=deaths_1979_1998/births_1979_1998

*Merge on other files
merge 1:1 countycode using `6', nogen keepusing(deaths population)
rename (deaths population) (deaths_1999_2016 births_1999_2016)
g inf_mort_1999_2016=deaths_1999_2016/births_1999_2016


*Make clean county and state variables
rename county countyname
tostring countycode, replace format(%05.0f) 
g state=substr(countycode, 1, 2)
g county=substr(countycode, 3, 5)
destring state county, replace

*Clean
keep state county deaths* births* inf_mort*
order state county 
tempfile pooled
save `pooled'

*---------------------------------------------------------------------
*Merge files together
*---------------------------------------------------------------------

*Make a balanced panel of counties
use state county using `by_year', clear
append using `pooled', keep(state county)
bysort state county: keep if _n==1
expand 49
bysort state county: g year=_n+1967

merge 1:1 state county year using `by_year', assert(1 3) nogen
merge m:1 state county using `pooled', assert(1 3) nogen

*Check to make sure correlatin with own pooled series is highest
*Data look good!
pwcorr inf_mort inf_mort_1968_1978 inf_mort_1979_1998 inf_mort_1999_2016 ///
	[w=births] if year==1973
pwcorr inf_mort inf_mort_1968_1978 inf_mort_1979_1998 inf_mort_1999_2016 ///
	[w=births] if year==1985
pwcorr inf_mort inf_mort_1968_1978 inf_mort_1979_1998 inf_mort_1999_2016 ///
	[w=births] if year==2008

*Label and output
label data "County panel of infant mortality"
label var state "State FIPS code"
label var county "County FIPS code"
label var year "Year"
label var births "Number of live births in year"
label var deaths "Number of infants <1 year old who died in year"
label var inf_mort "Infant mortality rate in year"
foreach p in 1968_1978 1979_1998 1999_2016 {
	label var births_`p' "Number of live births `p'"
	label var deaths_`p' "Number of infants <1 year old who died `p'"
	label var inf_mort_`p' "Infant mortality rate `p'"
}

*Output
compress
save "${root}/data/covariates/county_infmort.dta", replace
