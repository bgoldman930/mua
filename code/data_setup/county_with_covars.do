/***
• Build a spine of counties in the US from the NHGIS pull
• Attach wide covariates on the poverty rate, share senior, and population
***/


*------------------------------------------------------------------------------
* Build wide covariates from the NHGIS data
*------------------------------------------------------------------------------

import delimited "${root}/data/raw/nhgis0005_csv/nhgis0005_ts_nominal_county.csv", clear 

*Ensure the data are county year
isid statefp countyfp year

* Fill in the 2010 poverty data with the 2008-2012 ACS numbers
* This is because the long form has been replaced by the ACS by 2010 and the short form 
*	does not include information on earnings
replace year="2010" if year=="2008-2012"
ds gisjoin year state statefp statenh county countyfp countynh name, not
collapse (firstnm) `r(varlist)', by(year state statefp county countyfp)
destring year, replace

* Drop the county-year pairs missing either the total population or the age distribution
* This is two counties in Alaska and DC in 1970
* XX Might want to fix this missing data issue down the road
egen pop=rowtotal(b57*)
drop if pop~=av0aa

*Construct the poverty rate and the share senior
g poor_share=cl6aa/pop
egen seniors=rowtotal(b57ap b57aq b57ar)
g share_senior=seniors/pop

*Execute the reshape
keep year state statefp county countyfp pop poor_share share_senior
reshape wide pop poor_share share_senior, i(statefp county) j(year)

*Clean the file
rename (state county statefp countyfp) (state_name county_name state county)
order state_name county_name state county
sort state county 

tempfile nhgis_county_spine
save `nhgis_county_spine'

*------------------------------------------------------------------------------
* Kaveh's Georgia doctors
*------------------------------------------------------------------------------

import excel "${root}/data/raw/georgia_doctor_counts.xlsx", sheet("Sheet1") firstrow clear

*Merge on the state and county codes
drop if mi(county)
rename (state county) (state_name county_name)
merge 1:1 state_name county_name using `nhgis_county_spine', assert(2 3) keep(3) ///
	keepusing(state county pop1970 pop1980) nogen

*Build doctor variable
destring totpcpatientcare, replace
g kaveh_docspc1975=(1000*totpcpatientcare)/((pop1970+pop1980)/2)
	
*Clean
keep state county kaveh_docspc1975
destring kaveh_docspc1975, replace

*Output
compress
tempfile kaveh
save `kaveh'

*------------------------------------------------------------------------------
* Pull the doctor density data from the AHRF
*------------------------------------------------------------------------------

use "${root}/data/covariates/ahrf_covariates.dta", clear

* generate docs per capita 
forvalues y=1970(10)2010 {
	g docspc`y'=1000*total_mds_`y'/pop_`y'
}

* keep relevant vars
keep state county docspc*
isid state county

* save as tempfile
tempfile docspc
save `docspc'

*------------------------------------------------------------------------------
* Infant mortality data from O-Desk
*------------------------------------------------------------------------------

import excel "${root}/data/raw/vital_stats_1966_1970_secure.xlsx", sheet("Sheet1") firstrow clear

*Clean
rename *, lower
drop *total note
destring births* deaths*, replace force

*Create the inf_mort variables
forvalues y=1966/1970 {
	g inf_mort`y'=deaths`y'/births`y'
}

*Create a 5 year running average variable
egen births1966_1970=rowtotal(births*)
egen deaths1966_1970=rowtotal(deaths*)
g inf_mort1966_1970=deaths1966_1970/births1966_1970

*Output
rename (state county) (state_name county_name)
keep state_name county_name births* deaths* inf_mort*
tempfile inf_mort
save `inf_mort'

*------------------------------------------------------------------------------
* Infant mortality data from CDC Wonder
*------------------------------------------------------------------------------

* wide version of these data with 5 year moving averages
use "${root}/data/covariates/county_infmort.dta", clear

* keep only years with reliable wide data
tab year
keep if year<=1988

* reshape
reshape wide births deaths inf_mort, i(state county) j(year)

* generate the moving averages
forvalues i=1968/1984 {
	egen births`i'_`=`i'+4'=rowtotal(births`i' births`=`i'+1' births`=`i'+2' births`=`i'+3' births`=`i'+4')
	egen deaths`i'_`=`i'+4'=rowtotal(deaths`i' deaths`=`i'+1' deaths`=`i'+2' deaths`=`i'+3' deaths`=`i'+4')
	g inf_mort`i'_`=`i'+4'=deaths`i'_`=`i'+4'/births`i'_`=`i'+4'
}

*Output
rename * cdc_* 
rename (cdc_state cdc_county) (state county)
tempfile cdc_wide
save `cdc_wide'

*------------------------------------------------------------------------------
* MUA data from HRSA
*------------------------------------------------------------------------------

*Make a date variable
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

*Keep only designations (dropping withdrawls but leaving pending)
keep if 	(designationtypecode == "MUA" | ///
			designationtypecode == "MUA-GE") & ///
			(muapstatuscode == "D" | ///
			muapstatuscode == "P")
			
*Create an indicator for governor's exception
g governor_exception=designationtypecode=="MUA-GE"
			 
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

*Keep all counties designated + counties with tracts or MCDs inside designated
*This works because cty is first in the alphabet
*XX Later deal with geos designated at multiple dates (very small issue)
bysort state county (desig_level): keep if _n==1

*Do some cleaning
rename (providersper1000population infantmortalityrate percentageofpopulationage65andov percentofpopulationwithincomesat) ///
	(hrsa_docspc hrsa_inf_mort hrsa_share_senior hrsa_poor_share)
rename (v36 infantmortalityrateimuscore v34 v33) ///
	(hrsa_docspc_imu hrsa_inf_mort_imu hrsa_share_senior_imu hrsa_poor_share_imu)
rename imuscore imu

local vlist ///
	state 					county 				desig_level 		governor_exception 		date ///
	year 					month 				day 				imu						 ///
	hrsa_poor_share 		hrsa_share_senior 	hrsa_inf_mort		hrsa_docspc 			hrsa_poor_share_imu ///
	hrsa_share_senior_imu 	hrsa_inf_mort_imu 	hrsa_docspc_imu
keep `vlist'
sort date state county 

*Output
tempfile mua
save `mua'

*------------------------------------------------------------------------------
* Merge files together
*------------------------------------------------------------------------------

*XX ignore non-matchers for now as these appear to be small issues but revisit later
*Lots of these matching issues appear to be in Alaska + Dade county
*The non-matchers from the MUA file are mostly Puerto Rico and other islands

*Start with spine and then execute merges
use `nhgis_county_spine', clear
count
merge 1:1 state county using `docspc', keep(3) nogen
merge 1:1 state county using `kaveh', assert(1 3) nogen
merge 1:1 state_name county_name using `inf_mort', keep(1 3) nogen
merge 1:1 state county using `cdc_wide', keep(1 3) nogen
merge 1:1 state county using `mua', keep(1 3)
g mua=_merge==3
drop _merge
order `vlist'
order mua, after(county)
order state_name county_name, first
sort state county

*Output
compress
save "${root}/data/derived/mua_base.dta", replace
