/***
Purpose: Analyze basic properties of our treatment, control, and dropped counties
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

*Yellow to Blue map colors
local lightcolor "236 248 177"
local darkcolor "4 20 90"

*----------------------------------------------------------------------------
*Treatment vs. control
*----------------------------------------------------------------------------

project, uses("${root}/data/derived/cty_basefile.dta")
use "${root}/data/derived/cty_basefile.dta", clear

project, original("${root}/data/raw/county_list.dta") preserve
merge 1:1 county using "${root}/data/raw/county_list", nogen
replace treatment = -1 if mi(treatment)

*Standardize variables at the county level (unweighted)
drop *_st
foreach var in cruderate docs_per1k over65_2005 poor_share log_pop_density {
	sum `var' 
	g `var'_st = ((`var'-`r(mean)')/`r(sd)')
}

*Basic controls
graph hbar ///
	(mean) poor_share_st over65_2005_st docs_per1k_st cruderate_st log_pop_density_st, ///
	over(treatment, relabel(1 "Omitted" 2 "Control" 3 "Treatment") label(labsize(*.9))) ///
	title(" ") ytitle("Standardized Variable") ///
	ylabel(-1(.5)1) ymtick(##2) ///
	intensity(5) lintensity(1) ///
	bar(1, fcolor(navy) fintensity(inten60) lcolor(navy) lwidth(medium) lpattern(solid)) ///
	bar(2, fcolor(maroon) fintensity(inten60) lcolor(maroon) lwidth(medium) lpattern(solid)) ///
	bar(3, fcolor(green) fintensity(inten60) lcolor(green) lwidth(medium) lpattern(solid)) ///
	bar(4, fcolor(orange) fintensity(inten60) lcolor(orange) lwidth(medium) lpattern(solid)) ///
	bar(5, fcolor(gs6) fintensity(inten60) lcolor(gs6) lwidth(medium) lpattern(solid)) ///
	legend(order(1 "Share Poor" 2 "Share 65+" 3 "# Doctors" 4 "Inf. Mort." 5 "Pop. Dens.") ///
		size(*.7) row(1))
graph export "${root}/results/figures/samp_compare.pdf", replace
project, creates("${root}/results/figures/samp_compare.pdf") preserve

*Map of samples
maptile treatment, ///
	geography(county2000) ///
	legdecimals(0) ///
	stateoutline(*.28) ///
	ndfcolor(gs8) ///
	cutvalues(-1 0 1) ///
	propcolor ///
	rangecolor("`lightcolor'" "`darkcolor'") ///
	twopt(legend(order(4 "Treatment" 3 "Control" 2 "Omitted")) title(" "))
graph export "${root}/results/figures/samp_map.pdf", replace
project, creates("${root}/results/figures/samp_map.pdf") preserve

