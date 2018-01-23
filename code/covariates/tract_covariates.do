/***
Purpose: Build tract level data set from EOP clean data
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
*Read in raw NHGIS data to create fraction senior variable
*---------------------------------------------------------------------

*XX This variable does not correlate to share_seniors2000 - need to fix
project, original("${root}/data/raw/nhgis0003_ts_nominal_tract.csv")
import delimited "${root}/data/raw/nhgis0003_ts_nominal_tract.csv", clear

*Store tract codes
keep statefp countyfp tracta year b*
rename (statefp countyfp tracta) (state county tract)

*Drop the 1970 data
drop if year==1970

*Generate share senior variable
egen pop=rowtotal(b*)
egen senior=rowtotal(b57ap b57aq b57ar)
g share_senior=senior/pop

*Clean
keep state county tract year share_senior
tempfile senior
save `senior'

*---------------------------------------------------------------------
*Clean Alex Jenni's long covariates
*---------------------------------------------------------------------

project, original("${root}/data/raw/covariates_tract_long.dta")
use "${root}/data/raw/covariates_tract_long.dta", clear

rename (state10 county10 tract10) (state county tract)

*Keep a subset of the variables
keep ///
	state 				county				tract 				year ///
	pop popdensity 		hhinc_mean 			poor_share 			black_share ///
	hisp_share 			asian_share 		singleparent_share 	median_rent ///
	foreign_share 		household_size 		divorced_share 		married_share ///
	median_value 		lfp 				lfp_m 				lfp_w ///
	pct_manufacturing 	lead_share 			frac_kids_eng_only 	frac_kids_span ///
	nohs_share 			nohs_male_share 	nohs_female_share 	college_share ///
	college_male_share 	college_female_share 					share_innercity ///
	share_outercity 	share_rural 		share_owner 		share_renter ///
	student_teacher_	grad_4year 			grad_5year 			dropout ///
	poor_share_white 	poor_share_black 	poor_share_asian 	poor_share_hispanic ///
	med_hhinc_white 	med_hhinc_black 	med_hhinc_asian 	med_hhinc_hispanic
order ///
	state 				county				tract 				year ///
	pop popdensity 		hhinc_mean 			poor_share 			black_share ///
	hisp_share 			asian_share 		singleparent_share 	median_rent ///
	foreign_share 		household_size 		divorced_share 		married_share ///
	median_value 		lfp 				lfp_m 				lfp_w ///
	pct_manufacturing 	lead_share 			frac_kids_eng_only 	frac_kids_span ///
	nohs_share 			nohs_male_share 	nohs_female_share 	college_share ///
	college_male_share 	college_female_share 					share_innercity ///
	share_outercity 	share_rural 		share_owner 		share_renter ///
	student_teacher_	grad_4year 			grad_5year 			dropout ///
	poor_share_white 	poor_share_black 	poor_share_asian 	poor_share_hispanic ///
	med_hhinc_white 	med_hhinc_black 	med_hhinc_asian 	med_hhinc_hispanic

tempfile covars
save `covars'


*---------------------------------------------------------------------
*Final cleaning
*---------------------------------------------------------------------

*Use the perfectly clean final covariates from EOP to form tract spine
project, original("${root}/data/raw/covariates_tract_updated_v2.dta")
use state10 county10 tract10 ///
	using "${root}/data/raw/covariates_tract_updated_v2.dta", clear
rename (state10 county10 tract10) (state county tract)

*Expand for 1980-2010
expand 4
bysort state county tract: g year=(_n+1)*10+1960

*Merge on covariates
merge 1:1 state county tract year using `senior', keep(1 3) nogen
merge 1:1 state county tract year using `covars', keep(1 3) nogen

*Clean and output
order state county tract year pop
compress
save "${root}/data/covariates/tract_covariates.dta", replace
project, creates("${root}/data/covariates/tract_covariates.dta")
