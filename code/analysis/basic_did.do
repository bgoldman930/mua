/***
Purpose: Run basic difference in difference estimation 
***/

*---------------------------------------------------------------------------------
* Create predicted IMU score
*---------------------------------------------------------------------------------

use "${root}/data/derived/mua_base.dta", clear

*Document variance in infant mortality rates by population
*Less populus places have more variance—-harder to get the correct IMU without the exact data source
egen inf_mort_sd=rowsd(inf_mort1966 inf_mort1967 inf_mort1968 inf_mort1969 inf_mort1970)

*Cut to a sample of places with non-missing covariates
drop if mi(poor_share1970) | mi(inf_mort1966_1970) | mi(docspc1970) | mi(share_senior1970)

*Estimate the IMU score
buildimu, pov(poor_share1970) inf(inf_mort1966_1970) docs(docspc1970) old(share_senior1970) hat(imu_hat_1970)

* Generate a treatment and control group
* Keep only places designated in 1978, never designated, or designated later than 1988
rename year desig_year
keep if desig_year==1978 | desig_year>1988
g treatment=desig_year==1978
tab treatment, m

* Output temporary file
keep state county imu_hat_1970 treatment poor_share1970 inf_mort1966_1970 ///
	docspc1970 share_senior1970 pop1970 pop1980 pop1990
tempfile treat
save `treat'

* Merge on mortality datas
use "${root}/data/covariates/county_mort.dta", clear

*Merge on treatment
merge m:1 state county using `treat', assert(1 3) keep(3) nogen

* Limit to set of years around treatment
keep if inrange(year, 1968, 1988)

*---------------------------------------------------------------------------------
* Basic event study plots
*---------------------------------------------------------------------------------

* Generate a county indicator 
egen cty=group(state county)
isid cty year

* Generate event study style indicators
forvalues y=1968/1988 {
	g byte es`y'=treatment==1 & year==`y'
}

* Eliminate the 1977 coefficient as the reference period
drop es1977

* Store the median of the predicted IMU score
su imu_hat_1970, d
local med=`r(p50)'

* Run event studies over different IMU bandwidths 
forvalues i=3(3)39 {
	di "Doing bandwith `i'"
	preserve
	* Limit sample to correct bandiwth 
	g in_samp=inrange(imu_hat_1970, `med'-`i', `med'+`i')
	su in_samp
	keep if in_samp==1
	
	* Create empty variables to store estimates
	g esti_year=_n+1967
	replace esti_year=. if esti_year>1988
	g coef=.
	g hi=.
	g lo=.
	
	* Run regression and store estimates
	* Doesn't matter whether you absorb county or use treatment indicator since 
	* 	the panel is totally balanced
	areg ageadjustedrate treatment es1968-es1988, absorb(year) vce(cluster cty)
	tab treatment if year==1977, su(ageadjustedrate)
	forvalues y=1968/1988 {
		if `y'!=1977 {
			replace coef=_b[es`y'] if esti_year==`y'
			replace hi=coef+1.96*_se[es`y'] if esti_year==`y'
			replace lo=coef-1.96*_se[es`y'] if esti_year==`y'
		}
	}
	replace coef=0 if esti_year==1977
	twoway ///
	scatter coef esti_year, mcolor(plb1) || ///
	rcap hi lo esti_year, ///
	xline(1978, lcolor(gs5) lpattern(dash)) ///
	xtitle("Year") xlabel(1968(5)1988) ///
	ytitle("Age Adjusted Mortality Rates") ///
	title("IMU Bandiwth `i'") ///
	legend(off) 
	graph export "${root}/results/figures/es_bw`i'.pdf", replace

	
	restore
}
/*

* Run the event study regression
* Doesn't matter whether you absorb county or use treatment indicator since the panel is totally balanced
areg ageadjustedrate treatment es*, absorb(year) vce(cluster cty)

* Generate variables to store estimates and standard errors 
g esti_year=_n+1967 if _n<22
g coef=.
g hi=.
g lo=.
forvalues y=1968/1988 {
	if `y'!=1977 {
		replace coef=_b[es`y'] if esti_year==`y'
		replace hi=coef+1.96*_se[es`y'] if esti_year==`y'
		replace lo=coef-1.96*_se[es`y'] if esti_year==`y'
	}
}
replace coef=0 if esti_year==1977

twoway ///
	scatter coef esti_year, mcolor(plb1) || ///
	rcap hi lo esti_year, ///
	xline(1978, lcolor(gs5) lpattern(dash)) ///
	xtitle("Year") xlabel(1968(5)1988) ///
	ytitle("Age Adjusted Mortality Rates") ///
	title("IMU Bandiwth XX") ///
	legend(off) 
	






/*
g post=year>1978
g treatment=mua_1978==1
g did=post*treatment
egen cty=group(state county)
areg ageadjustedrate treatment did, absorb(year) vce(cluster cty)


forvalues i=1971/1985 {
		g tmp=year==`i'
		g inter`i'=tmp*treatment
		drop tmp
}
drop inter1977
areg ageadjustedrate treatment inter*, absorb(year) vce(cluster cty)


* These are the same (because of the balanced panel)
areg ageadjustedrate i.year inter*, absorb(cty) vce(cluster cty)
areg ageadjustedrate treatment inter*, absorb(year) vce(cluster cty)


* Try with X's
areg ageadjustedrate treatment imu_hat_1970 inter*, absorb(year) vce(cluster cty)

areg ageadjustedrate treatment imu_hat_1970 inter*, absorb(year) vce(cluster cty)
g yr=_n+1970 if _n<20
g coef=.
g hi=.
g lo=.
forvalues i=1971/1985 {
	cap replace coef=_b[inter`i'] if yr==`i'
	cap replace hi=coef+1.96*_se[inter`i'] if yr==`i'
	cap replace lo=coef-1.96*_se[inter`i'] if yr==`i'	
}

* Simple dif n' dif
reg ageadjustedrate treatment post did, vce(cluster cty)
