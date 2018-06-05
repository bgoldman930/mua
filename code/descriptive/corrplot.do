/***
Purpose: Construct correlation plot
***/

global rhs ///
	share_insured_18_64		share_rural_2010		popdensity2010 ///
	share_black2010 		pct_married2010			pct_foreign2010 ///
	share_seniors2010		frac_coll_plus2010		median_value2010 ///
	hhinc_mean2010			poor_share2010		
local rhs_count : word count ${rhs}

use "${root}/data/covariates/tract_covariates_wide", clear

*Collapse to the county level
collapse (mean) ${rhs} (rawsum) pop2010 [w=pop2010], by(state county)

*Merge on the 2010 doctor countrs from the AHRF
merge 1:1 state county using "${root}/data/covariates/ahrf_covariates", ///
	keep(1 3) nogen keepusing(total_mds_2010)
	
*Produce correlations
g docs_pers=total_mds_2010/pop2010
foreach x of global rhs {
	corr docs_pers `x' [w=pop2010]
	local r_`x'=`r(rho)'
}

*Pop into a data set
clear
set obs `rhs_count'
g order=_n
g var=""
g corr=.
forvalues i=1/`rhs_count' {
	replace var="`: word `i' of ${rhs}'" in `i'
	replace corr=`r_`: word `i' of ${rhs}'' in `i'
}
g neg=corr<0
replace corr=abs(corr)
g level="cty"
tempfile cty
save `cty'

*Replicate at the tract level

*Make doctors counts
use "${root}/data/derived/ama_tract_data", clear
rename tract ct
g state=substr(ct, 1, 2) 
g county=substr(ct, 3, 3) 
g tract=substr(ct, 6, 6) 
destring state county tract, replace 
keep if year==2009|year==2011
collapse (mean) tot, by(state county tract)
tempfile docs
save `docs'

use "${root}/data/covariates/tract_covariates_wide", clear

*Merge on the 2010 doctor countrs from the AMA data
merge 1:1 state county tract using `docs', ///
	keep(1 3) nogen keepusing(tot)
	
*Produce correlations
g docs_pers=tot/pop2010
replace docs_pers=0 if mi(docs_pers)
foreach x of global rhs {
	corr docs_pers `x' [w=pop2010]
	local r_`x'=`r(rho)'
}

*Pop into a data set
clear
set obs `rhs_count'
g order=_n
g var=""
g corr=.
forvalues i=1/`rhs_count' {
	replace var="`: word `i' of ${rhs}'" in `i'
	replace corr=`r_`: word `i' of ${rhs}'' in `i'
}
g neg=corr<0
replace corr=abs(corr)
g level="tract"
append using `cty'

*Produce scatter plot
twoway ///
	scatter order corr if neg==1 & level=="cty", mcolor(red) || ///
	scatter order corr if neg==0 & level=="cty", mcolor(green) || ///
	scatter order corr if neg==1 & level=="tract", mcolor(none) msymbol(none) || ///
	scatter order corr if neg==0 & level=="tract", mcolor(none) msymbol(none) || ///
	scatter order corr if neg==2, mcolor(gs7) msymbol(circle_hollow) || ///
	scatter order corr if neg==2, mcolor(gs7) ///
	ylabel( ///
		1 "Share insured" ///
		2 "Share rural" ///
		3 "Population density" ///
		4 "Share black" ///
		5 "Share married" ///
		6 "Share foreign" ///
		7 "Share senior" ///
		8 "Share college" ///
		9 "Median home value" ///
		10 "Mean household income" ///
		11 "Fraction below poverty line" ///
		, labsize(*.8) nogrid angle(0)) ///
	ytitle("") ///
	xlabel(0(0.2)1, grid gmax) ///
	xtitle("Magnitude of Correlation") ///
	title("Doctor Density and Local Characteristics") ///
	legend(order(6 "County")) 
graph export "${root}/results/figures/corr_plot_a.pdf", replace

twoway ///
	scatter order corr if neg==1 & level=="cty", mcolor(red) || ///
	scatter order corr if neg==0 & level=="cty", mcolor(green) || ///
	scatter order corr if neg==1 & level=="tract", mcolor(red) msymbol(circle_hollow) || ///
	scatter order corr if neg==0 & level=="tract", mcolor(green) msymbol(circle_hollow) || ///
	scatter order corr if neg==2, mcolor(gs7) msymbol(circle_hollow) || ///
	scatter order corr if neg==2, mcolor(gs7) ///
	ylabel( ///
		1 "Share insured" ///
		2 "Share rural" ///
		3 "Population density" ///
		4 "Share black" ///
		5 "Share married" ///
		6 "Share foreign" ///
		7 "Share senior" ///
		8 "Share college" ///
		9 "Median home value" ///
		10 "Mean household income" ///
		11 "Fraction below poverty line" ///
		, labsize(*.8) nogrid angle(0)) ///
	ytitle("") ///
	xlabel(0(0.2)1, grid gmax) ///
	xtitle("Magnitude of Correlation") ///
	title("Doctor Density and Local Characteristics") ///
	legend(order(5 "Tract" 6 "County")) 
graph export "${root}/results/figures/corr_plot_b.pdf", replace
