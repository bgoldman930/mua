/***
Purpose: Clean raw MUA data
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
*Basic cleaning - generate date variable
*---------------------------------------------------------------------

*Date variable
project, original("${root}/data/raw/mua_det.csv")
insheet using "${root}/data/raw/mua_det.csv", comma clear
g date = date(v53, "YMD")
format date %tdMon-YY
g year = year(date)
g month = month(date)
g day = day(date)
order date year month day
sort date

*Rename geography variables
rename v55 geo_type
rename minorcivildivisionfipscode mcd
rename commonstatecountyfipscode countyfips
rename censustract ct
sort year month geo_type
order year month geo_type mcd countyfips ct

*---------------------------------------------------------------------
*Read in raw MUA data and keep only county level designations
*---------------------------------------------------------------------

*Keep only designations(dropping withdrawls but leaving pending)
keep if 	(designationtypecode == "MUA" | ///
			designationtypecode == "MUA-GE") & ///
			(muapstatuscode == "D" | ///
			muapstatuscode == "P")
			
*Build state, county, and tract variables
tostring countyfips, replace format(%05.0f) 
split ct, parse(".")
g tract = ct1+ct2
replace tract="" if tract=="Not Applicable"
g state=substr(countyfips, 1, 2)
g county=substr(countyfips, 3, 5)
destring state county tract, replace
			
*Cleaner desig_level variable
g desig_level="cty" if geo_type=="SCTY"
replace desig_level="tract" if geo_type=="CT"
replace desig_level="mcd" if geo_type=="MCD"

*Reduce to one row per geo*designation
*If a county has been designated multiple times, keep the first instance
*Start with counties and MCD
preserve
keep if desig_level~="tract"
bysort state county (date): keep if _n == 1
assert mi(tract)
tempfile county
save `county'
restore

*Do tracts
keep if desig_level=="tract"
bysort state county tract (date): keep if _n == 1

*Append together
append using `county'

*Clean IMU score variables
rename imuscore imu 
rename percentofpopulationwithincomesat poor_share
rename percentageofpopulationage65andov share_senior
rename ruralstatusdescription rural
rename infantmortalityrate inf_mort

*Clean and output
keep state county tract desig_level date year month day imu poor_share share_senior inf_mort rural
order state county tract desig_level date year month day imu poor_share share_senior inf_mort rural
sort date state county tract
label var date "Date of designation"
save "${root}/data/derived/mua_base.dta", replace
project, creates("${root}/data/derived/mua_base.dta")
