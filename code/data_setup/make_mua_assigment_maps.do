/***
Purpose: Generate maps of mua assignment
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
*Append datasets at different designation levels
*---------------------------------------------------------------------

clear
foreach geo in cty mcd ct {
	project, uses("${root}/data/derived/mua_`geo'.dta") preserve 
	append using "${root}/data/derived/mua_`geo'.dta"
}

*For places designated twice within the same day, keep the largest population
bysort zcta date (zpoppct): keep if _n == _N

*Keep first designation unless it affects less than 5% of population
g small = (zpoppct<5)
bysort zcta5 (small date): keep if _n == 1
drop small

*---------------------------------------------------------------------
*Build maps
*---------------------------------------------------------------------

rename zcta5 zip5
forvalues yr = 1980(5)2015 {
	g mua_`yr' = (year<=`yr' & zpoppct>=80 & ~mi(zpoppct))
	maptile mua_`yr', ///
		geo(zip5) ///
		rangecolor(white red) ///
		ndfcolor(white) ///
		stateoutline(*.35) ///
		cutvalues(0 0.001 0.9999 1) ///
		twopt( ///
		legend(off) ///
		title("MUA Designation - `yr'")) 
	graph export "${root}/results/figures/mua_`yr'.png", width(2400) replace
	project, creates("${root}/results/figures/mua_`yr'.png") preserve
}
