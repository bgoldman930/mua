/*
Purpose: Create zip-X crosswalks, X=county, mcd, ct
*/

* Set directories
return clear
do `"`c(sysdir_personal)'profile.do"'
capture project, doinfo
global root `r(pdir)'
set more off 

* zip-county cw
** assign to each zip the county in which the majority of the zip's pop lives:
project, original("${root}/data/raw/zcta_county.csv")
insheet using "${root}/data/raw/zcta_county.csv", comma clear
rename zcta5 zip
gsort zip -poppt
bys zip: keep if _n==1
keep zip state county
gen state2=string(state)
gen county2=string(county,"%03.0f")
gen county_fips= state2+county2
destring county_fips, replace
drop state county state2 county2
rename county_fips county
save "${root}/data/derived/cw_zip_county", replace
project, creates("${root}/data/derived/cw_zip_county.dta")

* zip-mcd cw
** assign to each zip the subcounty in which the majority of the zip's pop lives:
project, original("${root}/data/raw/zcta_cousub.csv")
insheet using "${root}/data/raw/zcta_cousub.csv", comma clear
rename zcta5 zip
gsort zip -poppt
bys zip: keep if _n==1
keep zip state county cousub
gen state2=string(state)
gen county2=string(county,"%03.0f")
gen cousub2=string(cousub,"%05.0f")
gen cousub_fips= state2+county2+cousub2
destring cousub_fips, replace
drop state county cousub state2 county2 cousub2
rename cousub_fips mcd
save "${root}/data/derived/cw_zip_mcd", replace
project, creates("${root}/data/derived/cw_zip_mcd.dta")

* zip-ct cw
** assign to each zip the census tract in which the majority of the zip's pop lives:
project, original("${root}/data/raw/zcta_tract.csv")
insheet using "${root}/data/raw/zcta_tract.csv", comma clear
rename zcta5 zip
gsort zip -poppt
bys zip: keep if _n==1
keep zip state county tract
gen state2=string(state)
gen county2=string(county,"%03.0f")
gen county_fips= state2+county2
destring county_fips, replace
gen tract2=string(tract,"%06.0f")
gen tract3=substr(tract2,1,4)+"."+substr(tract2,5,2)
drop state county state2 county2 tract tract2
rename county_fips county
rename tract3 ct
save "${root}/data/derived/cw_zip_ct", replace
project, creates("${root}/data/derived/cw_zip_ct.dta")
