/***
Purpose: Pull useful variables from AHRF
***/

*---------------------------------------------------------------------
*Read in raw AHRF and keep variables of interest
*---------------------------------------------------------------------

clear
clear matrix
clear mata
set maxvar 10000
use "${root}/data/raw/ahrf.dta", clear

*Describe variables in a log
describe

*Generate state and county code
g state=substr(f00002, 1, 2)
g county=substr(f00002, 3, 3)
destring state county, replace

*---------------------------------------------------------------------
*Keep variables of interest
*---------------------------------------------------------------------

*Total active MD's non-federal
foreach y in 60 70 80 90 00 05 10 11 12 13 14 15 {
	if `y'>18 local stub=1900+`y'
	else local stub=2000+`y'
	rename f08857`y' total_mds_`stub'
}

*County population estimates
foreach y in 95 05 06 07 08 09 11 12 13 14 15 16 {
	if `y'>18 local stub=1900+`y'
	else local stub=2000+`y'
	rename f11984`y' pop_`stub'
}

*Decennial years
rename f0453010 pop_2010
rename f0453000 pop_2000
rename f1139790 pop_1990
rename f1139780 pop_1980
rename f0017970 pop_1970
rename f1139860 pop_1960

*Correct the earlier years so they are no longer in 100's
forvalues y=1960(10)1990 {
	replace pop_`y'=pop_`y'*100
	label var pop_`y' "Census Population `y'"
}

*Black population
foreach y in 05 11 12 13 14 15 {
	if `y'>18 local stub=1900+`y'
	else local stub=2000+`y'
	rename f13979`y' black_male_pop_`stub'
	rename f13980`y' black_female_pop_`stub'
}

*White population
foreach y in 05 11 12 13 14 15 {
	if `y'>18 local stub=1900+`y'
	else local stub=2000+`y'
	rename f13926`y' white_male_pop_`stub'
	rename f13927`y' white_female_pop_`stub'
}

*Number of seniors
foreach y in 05 11 12 13 14 15 {
	if `y'>18 local stub=1900+`y'
	else local stub=2000+`y'
	rename f14083`y' seniors_pop_`stub'
}
rename f1484010 seniors_pop_2010
rename f1348310 median_age_2010
rename f1348300 median_age_2000

*Incarceration
rename f1489010 incarcerated_pop_2010
rename f1165600 incarcerated_pop_2000

*Nursing homes
rename f1489210	nursing_home_pop_2010
rename f1165700 nursing_home_pop_2000

*Low birth weight
rename f1255312 low_wgt_births_2012_2014
rename f1255311 low_wgt_births_2011_2013
rename f1255310 low_wgt_births_2010_2012
rename f1255309 low_wgt_births_2009_2011
rename f1255308 low_wgt_births_2008_2010

*5 year infant mortality rate
foreach y in 96 01 02 03 04 05 06 07 08 09 10 {
	if `y'>18 local stub=1900+`y'
	else local stub=2000+`y'
	rename f12669`y' inf_mort_`stub'_`=`stub'+4'
}

*Poverty share
foreach y in 05 10 11 12 13 14 15 {
	if `y'>18 local stub=1900+`y'
	else local stub=2000+`y'
	rename f13223`y' poor_pop_`stub'
}

*Clean and output
keep	state				county ///
		pop_*				total_mds* 			black_* ///
		white_*				seniors_*			median_* ///
		incarcerated_*		nursing_*			low_wgt_* ///
		inf_mort_*			poor_pop_*
order	state				county ///
		pop_*				total_mds* 			black_* ///
		white_*				seniors_*			median_* ///
		incarcerated_*		nursing_*			low_wgt_* ///
		inf_mort_*			poor_pop_*
compress
save "${root}/data/covariates/ahrf_covariates.dta", replace
