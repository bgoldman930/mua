/***
Purpose: Life expectancy vs. doctor counts
***/

global rhs ///
	share_insured_18_64		share_rural_2010		popdensity2010 ///
	share_black2010 		pct_married2010			pct_foreign2010 ///
	share_seniors2010		frac_coll_plus2010		median_value2010 ///
	hhinc_mean2010			poor_share2010			poor_share2000

use "${root}/data/covariates/tract_covariates_wide", clear

*Collapse to the county level
collapse (mean) ${rhs} (rawsum) pop2010 [w=pop2010], by(state county)

*Merge on the 2010 doctor countrs from the AHRF
merge 1:1 state county using "${root}/data/covariates/ahrf_covariates", ///
	keep(1 3) nogen keepusing(total_mds_2010)
	
*Produce correlations
g docs_pers=1000*(total_mds_2010/pop2010)

*Generate combined county variable
tostring county, format(%03.0f) gen(c)
tostring state, format(%02.0f) gen(s)
g cty=s+c
destring cty, replace
drop s c

*Merge on the life expectency data
merge 1:1 cty using "${root}/data/raw/health_ineq_online_table_11", keep(3) nogen

*Make a pooled LE variable
egen count=rowtotal(count_*)
forvalues i=1/4 {
	foreach g in M F {
		g esti_`g'_`i'=(count_q`i'_`g'/count)*le_raceadj_q`i'_`g'
	}
}
egen le=rowtotal(esti_*)
drop esti*

*Make a by gender LE variable
foreach g in M F {
	egen count_`g'=rowtotal(count_q*_`g')
	forvalues i=1/4 {
		g esti_`i'=(count_q`i'_`g'/count_`g')*le_raceadj_q`i'_`g'
	}
	egen le_`g'=rowtotal(esti_*)
	drop esti_*
}

*Make an in income LE variable
forvalues i=1/4 {
	egen count_q`i'=rowtotal(count_q`i'_*)
	foreach g in M F {
		g esti_`g'=(count_q`i'_`g'/count_q`i')*le_raceadj_q`i'_`g'
	}
	egen le_q`i'=rowtotal(esti_*)
	drop esti_*
}

*Baseline plot of LE vs. doctors
reg le docs_pers [w=pop2010]

binscatter le docs_pers [w=pop2010], ///
	lcolor(navy) ///
	xtitle("Doctors per 1,000 Residents") ///
	ytitle("Life Expectancy") ///
	ylabel(, gmax) ///
	title("Doctor Density in 2010 and Life Expectancy 2001-2014") ///
	text (82.7 7 "Slope: 0`=round(_b[docs_pers], .001)' (0`=round(_se[docs_pers], .001)')")
graph export "${root}/results/figures/bin_le_docs.pdf", replace

*By income
reg le_q1 docs_pers [w=count_q1]
local b_1	: di %5.3f _b[docs_pers]
local se_1	: di %5.3f _se[docs_pers]

reg le_q4 docs_pers [w=count_q1]
local b_4	: di %5.3f _b[docs_pers]
local se_4	: di %5.3f _se[docs_pers]


binscatter le_q1 le_q4 docs_pers [w=pop2010], ///
	lcolor(dkorange black) mcolor(dkorange black) ///
	xtitle("Doctors per 1,000 Residents") ///
	ytitle("Life Expectancy") ///
	ylabel(, gmax) ///
	title(" ") ///
	legend(pos(3) region(fcolor(none)) ring(0) col(1) ///
		order(2 "4th Quartile - Slope: 0`=round(`b_4', .001)' (0`=round(`se_4', .001)')" ///
		1 "1st Quartile - Slope: 0`=round(`b_1', .001)' (0`=round(`se_1', .001)')"))
graph export "${root}/results/figures/bin_le_inc_docs.pdf", replace
