/***
Purpose: Binned scatter plot between doctor density and poverty rate
***/

*** County Level ***

use "${root}/data/raw/covariates_tract_wide", clear
rename (state10 county10 tract10) (state county tract)

*Collapse to the county level
collapse (mean) poor_share2010 (rawsum) pop2010 [w=pop2010], by(state county)

*Merge on the 2010 doctor countrs from the AHRF
merge 1:1 state county using "${root}/data/covariates/ahrf_covariates", ///
	keep(1 3) nogen keepusing(total_mds_2010)

g docs_pers=1000*(total_mds_2010/pop2010)
replace poor_share2010=100*poor_share2010

binscatter docs_pers poor_share2010 [w=pop2010], ///
	lcolor(navy) ///
	xtitle("Fraction Below Poverty Line") ///
	ytitle("Doctors per 1,000 Residents") ///
	title("Doctor Density and County Level Poverty Rates - 2010") ///
	ylabel(1.5(1.5)6, gmax) yscale(range(1.5 6.3)) 
graph export "${root}/results/figures/bin_docs_poor_cty.pdf", replace

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

*** Tract Level ***

use "${root}/data/raw/covariates_tract_wide", clear
rename (state10 county10 tract10) (state county tract)

*Merge on the 2010 doctor countrs from the AMA data
merge 1:1 state county tract using `docs', ///
	keep(1 3) nogen keepusing(tot)
g docs_pers=1000*(tot/pop2010)
replace docs_pers=0 if mi(docs_pers)
replace poor_share2010=100*poor_share2010

su docs_pers [w=pop2010], d
binscatter docs_pers poor_share2010 [w=pop2010] if docs_pers>`r(p1)' & docs_pers<`r(p99)', linetype(none) ///
	xtitle("Fraction Below Poverty Line") ///
	ytitle("Doctors per 1,000 Residents") ///
	title("Doctor Density and Tract Level Poverty Rates - 2010") ///
	ylabel(1.5(1.5)6, gmax) yscale(range(1.5 6.3)) 
graph export "${root}/results/figures/bin_docs_poor_tract.pdf", replace
