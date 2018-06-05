/***
Purpose: Clean county population data
***/

*---------------------------------------------------------------------
*Read in already clean NBER file
*---------------------------------------------------------------------

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
 
*XX Something seems off here
drop if state==0 | county==0
reshape long pop_, i(state county) j(year)
binscatter pop_ year, discrete
