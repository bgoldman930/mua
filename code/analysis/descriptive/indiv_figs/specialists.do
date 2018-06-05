/***
Produce a map and correlation plot for specialists only
***/

global rhs ///
	share_insured_18_64		share_rural_2010		popdensity2010 ///
	share_black2010 		pct_married2010			pct_foreign2010 ///
	share_seniors2010		frac_coll_plus2010		median_value2010 ///
	hhinc_mean2010			poor_share2010		
local rhs_count : word count ${rhs}

*Yellow to Blue
local lightcolor "236 248 177"
local darkcolor "4 20 90"

use "${root}/data/raw/covariates_tract_wide", clear
rename (state10 county10 tract10) (state county tract)

*Collapse to the county level
collapse (mean) ${rhs} (rawsum) pop2010 [w=pop2010], by(state county)
tempfile covars
save `covars'

use if year==2009 | year==2011 using "${root}/data/derived/ama_tract_data", clear

egen primarycare=rowtotal(fp gp im mpd fpg img pd obg)
gen specialist = tot-primarycare

*Collapse to estimate 2010 count
rename tract ct
g state=substr(ct, 1, 2) 
g county=substr(ct, 3, 3) 
g tract=substr(ct, 6, 6) 
collapse (mean) specialist, by(state county tract)
collapse (sum) specialist, by(state county)
g cty=state+county
destring state county, replace

*Merge on county populations
merge 1:1 state county using `covars', keep(3) 
rename (state county) (st c)
rename cty county
destring county, replace

*Specialist counts
g spec_pers_2010=1000*(specialist/pop2010)

*Specialist per person
foreach y in 2010 {
	xtile hold = spec_pers_`y', nquantiles(8)
	sum spec_pers_`y' if hold == 8
	local big 		: di %2.1f `r(min)'
	sum spec_pers_`y' if hold == 1
	local small		: di %2.1f `r(max)'
	maptile spec_pers_`y', ///
		n(8) ///
		geography(county2000) ///
		legdecimals(1) ///
		rangecolor("`lightcolor'" "`darkcolor'") ///
		stateoutline(*.28) ///
		ndfcolor(gs11) ///
		twopt(legend(lab(9 ">`big'") lab(2 "<`small'")) title(" "))
	graph export "${root}/results/figures/spec_dens_`y'.png", width(1500) replace
	drop hold 
}


*Merge on the 2010 doctor countrs from the AHRF
drop county
rename (st c) (state county)
merge 1:1 state county using "${root}/data/covariates/ahrf_covariates", ///
	keep(1 3) nogen keepusing(total_mds_2010)
g docs_pers_2010=total_mds_2010/pop2010

*** Build the correlation plot *** 

*Produce correlations
foreach x of global rhs {
	corr docs_pers_2010 `x' [w=pop2010]
	local d_`x'=`r(rho)'
	
	corr spec_pers_2010 `x' [w=pop2010]
	local s_`x'=`r(rho)'
}

*Pop into a data set
clear
set obs `rhs_count'
g order=_n
foreach j in d s {
	g var_`j'=""
	g corr_`j'=.
	forvalues i=1/`rhs_count' {
		replace var_`j'="`: word `i' of ${rhs}'" in `i'
		replace corr_`j'=``j'_`: word `i' of ${rhs}'' in `i'
	}
	g neg_`j'=corr_`j'<0
	replace corr_`j'=abs(corr_`j')
}

twoway ///
	scatter order corr_s if neg_s==1, mcolor(red) msymbol(square)  || ///
	scatter order corr_s if neg_s==0, mcolor(green) msymbol(square) || ///
	scatter order corr_d if neg_d==1, mcolor(red) msymbol(square_hollow) || ///
	scatter order corr_d if neg_d==0, mcolor(green) msymbol(square_hollow) || ///
	scatter order corr_d if neg_d==2, mcolor(gs7) msymbol(square_hollow) || ///
	scatter order corr_d if neg_d==2, mcolor(gs7) msymbol(square) ///
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
	title("Specialist Density and Local Characteristics") ///
	legend(order(5 "Primary Care" 6 "Specialists")) 
graph export "${root}/results/figures/spec_corr_plot.pdf", replace
