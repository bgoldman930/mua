/***
Purpose: Construct baseline physician density map
***/

*Yellow to Blue
local lightcolor "236 248 177"
local darkcolor "4 20 90"

*Load in the county level AHRF file
use "${root}/data/covariates/ahrf_covariates", clear
keep state county total_mds_* poor_pop_* pop_*

*Combine county ID variable
tostring county, format(%03.0f) replace
tostring state, format(%02.0f) replace
replace county=state+county
destring county, replace

*Generate doctors per person
foreach y in 2000 2010 {
	g docs_pers_`y'=1000*(total_mds_`y'/pop_`y')
}

*Correlation between populations and doctors
corr total_mds_2010 pop_2010
di "Correlation between population and doctor counts: `=round(`r(rho)', 0.01)'"

*Doctors per person
foreach y in 2000 2010 {
	xtile hold = docs_pers_`y', nquantiles(8)
	sum docs_pers_`y' if hold == 8
	local big 		: di %2.1f `r(min)'
	sum docs_pers_`y' if hold == 1
	local small		: di %2.1f `r(max)'
	maptile docs_pers_`y', ///
		n(8) ///
		geography(county2000) ///
		legdecimals(1) ///
		rangecolor("`lightcolor'" "`darkcolor'") ///
		stateoutline(*.28) ///
		ndfcolor(gs11) ///
		twopt(legend(lab(9 ">`big'") lab(2 "<`small'")) title(" "))
	graph export "${root}/results/figures/docs_dens_`y'.png", width(500) replace
	drop hold 
}

*Statistics for slides

*What fraction of the population lives in counties that contain 80% of doctors
egen tot_pop=total(pop_2010)
g frac_pop=pop_2010/tot_pop
egen tot_docs=total(total_mds_2010)
g frac_docs=total_mds_2010/tot_docs

gsort - frac_docs
g run_sum=sum(frac_docs)
preserve
keep if run_sum<=0.8 // Keep the counties that contain 80% of doctors
collapse (sum) pop_2010 (first) tot_pop
g pct=100*(pop_2010/tot_pop)
su pct
di "`=round(`r(mean)', .01)'% of people live in counties that contain 80% of doctors"
restore

*50% of doctors work in XX% of counties
count
local counties `r(N)'
g hold=_n
su hold if run_sum<=.5
di "50% of doctors work in `=round(100*(`r(max)'/`counties'), .01)'% of counties"

*These counties contain XX% of the population
keep if run_sum<=.5
collapse (sum) pop_2010 (first) tot_pop
g pct=100*(pop_2010/tot_pop)
su pct
di "These counties contain `=round(`r(mean)', .01)'% of total population"
