/***
Purpose: Trends in doctor density
***/

global rhs ///
	share_insured_18_64		share_rural_2010		popdensity2010 ///
	share_black2010 		pct_married2010			pct_foreign2010 ///
	share_seniors2010		frac_coll_plus2010		median_value2010 ///
	hhinc_mean2010			poor_share2010			poor_share2000
local rhs_count : word count ${x}

use "${root}/data/raw/covariates_tract_wide", clear
rename (state10 county10 tract10) (state county tract)

*Collapse to the county level
collapse (mean) ${rhs} (rawsum) pop2010 [w=pop2010], by(state county)
tempfile covar
save `covar'

*Store county level population by year
use "${root}/data/covariates/ahrf_covariates", clear
keep state county pop_*
g pop_2003=(pop_2000+pop_2005)/2
reshape long pop_, i(state county) j(year)
rename pop_ pop
tempfile pop
save `pop' 

*Bring in the doctor data
use tract year tot using "${root}/data/derived/ama_tract_data", clear
rename tract ct
g state=substr(ct, 1, 2)
g county=substr(ct, 3, 3) 
g tract=substr(ct, 6, 6) 
destring state county tract, replace 

*Collapse to the county level
collapse (sum) docs=tot, by(state county year)

*Merge on other variables
merge 1:1 state county year using `pop', keep(1 3) nogen
merge m:1 state county using `covar', keep(1 3) nogen 
g docs_pers=1000*(docs/pop)
g rural=share_rural_2010>.8
su poor_share2000 [w=pop] if year==2000, d
g hi_pov=poor_share2000>`r(p75)' if ~mi(poor_share2000) & ///
	(poor_share2000>`r(p75)' | poor_share2000<`r(p25)')

su docs_pers [w=pop] if year==2000, d
g tmp=docs_pers>`r(p75)' if ~mi(docs_pers) & year==2000 & ///
	(docs_pers>`r(p75)' | docs_pers<`r(p25)')
egen hi_docs=max(tmp), by(state count) 

*Plots
binscatter docs_pers year [w=pop], discrete ///
	lcolor(navy) ///
	ytitle("Doctors per 1,000 Residents") ///
	xtitle("Year") ///
	xlabel(2000(5)2015) xmtick(##5) ///
	ylabel(2.9(.2)3.5, gmax) ///
	title(" ") 
graph export "${root}/results/figures/bin_docs_trend.pdf", replace


binscatter docs_pers year [w=pop], discrete by(rural) ///
	lcolor(black dkorange) mcolor(black dkorange) ///
	ytitle("Doctors per 1,000 Residents") ///
	xtitle("Year") ///
	xlabel(2000(5)2015) xmtick(##5) ///
	ylabel(0(1)4, gmax) ///
	title(" ") ///
	legend(ring(0) pos(5) col(1) region(fcolor(none)) ///
		order(2 "Rural" 1 "Non-rural")) 
graph export "${root}/results/figures/bin_docs_rural_trend.pdf", replace


binscatter docs_pers year [w=pop], discrete by(hi_docs) ///
	lcolor(black dkorange) mcolor(black dkorange) ///
	ytitle("Doctors per 1,000 Residents") ///
	xtitle("Year") ///
	ylabel(0(2)8, gmax) ///
	xlabel(2000(5)2015) xmtick(##5) ///
	title(" ") ///
	legend(ring(0) pos(11) col(1) region(fcolor(none)) bmargin(t=5) ///
		order(1 "Low Doc/Pers in 2000" 2 "High Doc/Pers in 2000")) 
graph export "${root}/results/figures/bin_docs_bydocs_trend.pdf", replace

*Map trends by county
tostring county, format(%03.0f) replace
tostring state, format(%02.0f) replace
replace county=state+county
destring county, replace
statsby _b, by(county) clear: reg docs_pers year

*Yellow to Blue
local lightcolor "236 248 177"
local darkcolor "4 20 90"
xtile hold = _b_year, nquantiles(8)
sum _b_year if hold == 8
local big 		: di %5.3f `r(min)'
sum _b_year if hold == 1
local small		: di %5.3f `r(max)'
maptile _b_year, ///
	n(8) ///
	geography(county2000) ///
	legdecimals(3) ///
	rangecolor("`lightcolor'" "`darkcolor'") ///
	stateoutline(*.28) ///
	ndfcolor(gs11) ///
	twopt(legend(lab(9 ">`big'") lab(2 "<`small'") size(*.8)) title(" "))
graph export "${root}/results/figures/docs_dens_trends.pdf", replace
drop hold 
