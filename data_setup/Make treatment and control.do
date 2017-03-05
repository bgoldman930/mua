/*
Purpose: Create list of treatment and control counties
*/

* Set directories
return clear
do `"`c(sysdir_personal)'profile.do"'
capture project, doinfo
global root `r(pdir)'
set more off 

*---------------------------------------------------------------------
*Create list of counties in treatment group
*---------------------------------------------------------------------

project, uses("${root}/data/derived/mua.dta")
use "${root}/data/derived/mua.dta", clear
reg imuscore providersper1000population infantmortalityrate percentofpopulationwithincomesat percentageofpopulationage65andov 

*Keep in sample counties
keep if geo_type == "SCTY" & year>=2004 & year<=2012 ///
	& ruralstatusdescription == "Rural"
	
*Count duplicates (6% show up more than once)
bysort county: g tot = _N	
g ind = (tot>1)
sum ind

*Keep first designation date and IMU score
sort county year month
collapse ///
	(first) imuscore ///
			desig_year			=year ///
			desig_month			=month ///
			hrsa_docsper1000	=providersper1000population ///
			hrsa_pop_inmua		=designationpopulationinamedicall ///
			hrsa_infmort		=infantmortalityrate ///
			hrsa_pct_poor		=percentofpopulationwithincomesat ///
			hrsa_pct_over65		=percentageofpopulationage65andov, ///
	by(county)
	
g treatment = 1
tempfile oursamp
save `oursamp', replace

*---------------------------------------------------------------------
*Create MCD to County crosswalk
*---------------------------------------------------------------------

*Read in zip level mcd crosswalk
project, uses("${root}/data/derived/cw_zip_mcd.dta")
use "${root}/data/derived/cw_zip_mcd", clear

*Merge on counties by zip code
project, uses("${root}/data/derived/cw_zip_county.dta") preserve
merge 1:1 zip using "${root}/data/derived/cw_zip_county", nogen

*Get rid of duplicate zip rows
drop zip
bysort mcd county: keep if _n == 1

*For few that are assigned multiple counties, choose random
g r = runiform()
sort mcd r
collapse (first) county, by(mcd)

tempfile cw_mcd_cty
save `cw_mcd_cty', replace

*---------------------------------------------------------------------
*Create list of rural places
*---------------------------------------------------------------------

project, uses("${root}/data/derived/mua.dta")
use "${root}/data/derived/mua.dta", clear

*Take mode rural status by county (for those with CT designation)
egen most = mode(ruralstatuscode), by(county)
keep if most == ruralstatuscode
bysort county: keep if _n == 1
g rural = (ruralstatuscode == "R")
keep rural county
tempfile rural
save `rural', replace

*---------------------------------------------------------------------
*Create list of counties in control group
*---------------------------------------------------------------------

use "${root}/data/derived/mua.dta", clear

*Create spine of rural counties with MUA designation
keep if geo_type == "MCD" | geo_type == "SCTY"
		
*Merge on counties to the MCDs
merge m:1 mcd using `cw_mcd_cty'
drop if _m == 2
drop _m

keep county
bysort county: keep if _n == 1

g ever_mua = 1
di _N

tempfile toss_out
save `toss_out', replace

*---------------------------------------------------------------------
*Create base file
*---------------------------------------------------------------------

project, original("${root}/data/raw/cty_covars.dta")
use "${root}/data/raw/cty_covars", clear
drop causal* perm* 

*Merge on treatment group
merge 1:1 county using `oursamp'
drop if _m == 2
drop _m

*Merge on ever_mua
merge 1:1 county using `toss_out'
drop if _m == 2
drop _m

*Merge on rural indicator
merge 1:1 county using `rural'
drop if _m == 2
drop _m

*Merge on Census % over 65
project, uses("${root}/data/derived/cty_over_65_shares.dta") preserve
merge 1:1 county using "${root}/data/derived/cty_over_65_shares", keepusing(over*)
drop if _m == 2
drop _m

*Merge on population by county
project, uses("${root}/data/derived/cty_pop.dta") preserve
merge 1:1 county using "${root}/data/derived/cty_pop", keepusing(pop*)
drop if _m == 2
drop _m

*Merge on doctor counts by county
project, original("${root}/data/raw/npi_cty_07to14.dta") preserve
merge 1:1 county using "${root}/data/raw/npi_cty_07to14", keepusing(npi_count*)
foreach yr in 2007 2009 2011 2012 2013 2014 {
	g docs_1k_`yr' = npi_count`yr'/pop`yr'
}
egen docs_per1k = rowmean(docs_1k_*)
*g docs_per1k = npi_count2007*1000/cty_pop2000
drop if _m == 2
drop _m

*Merge on infant mortality
project, uses("${root}/data/derived/cty_infmort99to15.dta") preserve
merge 1:1 county using "${root}/data/derived/cty_infmort99to15"
drop if _m == 2
drop _m

*Create control group
replace treatment = 0 if ever_mua == .

*Predict rural variable from covariates
reg rural log_pop_density intersects_msa
predict yhat, xb
replace yhat = 0 if yhat<.5
replace yhat = 1 if yhat>=.5
replace rural = yhat if mi(rural)
drop yhat ind

*Remove non-rural places from the control
replace treatment = . if rural == 0 & treatment == 0

*Get rid of those in treatment who are "governer's exception"
replace treatment = . if imuscore>62 & imuscore<.
replace treatment = -1 if mi(treatment)
tab treatment [w=cty_pop2000]

*---------------------------------------------------------------------
*Use RD design to further revise treatment and control
*---------------------------------------------------------------------

g samp = ( ///
	~mi(imuscore) & ///
	~mi(hrsa_docsper1000) & ///
	~mi(hrsa_infmort) & ///
	~mi(hrsa_pct_poor) & ///
	~mi(hrsa_pct_over65))

*Fix IMU = 0 when all right data is missing (HRSA error)
replace imuscore = . if imuscore ==0	
	
*Fit IMU score against raw HRSA data
reg imuscore hrsa_docsper1000 hrsa_infmort hrsa_pct_poor hrsa_pct_over65 if samp == 1
*Compare to our variables 
reg imuscore docs_per1k cruderate poor_share over65_2005 if samp == 1

*Fill in missing infant mortality data
reg cruderate poor_share
predict inf, xb
g crude_imp = 1 if mi(cruderate) & ~mi(inf)
replace cruderate = inf if mi(cruderate)
drop inf

*Fit all IMU data on our data to create sample
reg imuscore docs_per1k cruderate poor_share over65_2005
	
*Get fitted values
predict imuhat, xb
sum imuhat poor_share docs_per1k if treatment == 1, d
sum imuhat poor_share docs_per1k if treatment == 0, d

*Take MUA places near threshold 
replace treatment = -1 if treatment == 1 & imuhat>62 & ~mi(imuhat)

*Take poorest third of the control, for now
replace treatment = -1 if treatment == 0 & imuhat>62 & ~mi(imuhat)
replace treatment = -1 if mi(imuhat) & treatment == 0

tab treatment [w=cty_pop2000]
tab treatment

*Replace imputed infant mortality with missing
replace cruderate = . if crude_imp == 1

save ${root}/data/derived/cty_basefile, replace
project, creates("${root}/data/derived/cty_basefile.dta")
