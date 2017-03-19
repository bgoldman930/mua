/***
Purpose: Does MUA designation cause an increase in the number of doctors?
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

*---------------------------------------------------------------------
*Do MUA's get more doctors after designation
*---------------------------------------------------------------------

project, uses("${root}/data/derived/cty_basefile.dta")
use "${root}/data/derived/cty_basefile.dta", clear

keep county pop2* desig_year npi_count* treatment statename cz rural
reshape long pop npi_count, i(county desig_year treatment) j(year)
g yr_st = year-desig_year
replace yr_st = year if treatment == 0
g doc = 1000*(npi_count/pop)

preserve 
*XX decide if dropping below is appropriate for annual F.E.
drop if treatment == -1
g post = (yr_st>=0 & ~mi(yr_st))
g inter = post*yr_st

*Build fixed effects variable, between,and fixed+time
xtset county year

*Raw model
reg doc post yr_st inter if treatment == 1
local b_base 		: di %5.3f _b[inter]
local se_base		: di %5.3f _se[inter]

*Remove county fixed effects
egen tmp = mean(doc), by(county)
g doc_ctyfx = doc-tmp
drop tmp
xtreg doc post yr_st inter if treatment == 1, fe
local b_ctyfx 		: di %5.3f _b[inter]
local se_ctyfx		: di %5.3f _se[inter]

*Remove time fixed effects
egen tmp = mean(doc), by(year)
g doc_yrfx = doc-tmp
drop tmp
xtreg doc post yr_st inter if treatment == 1, be
local b_yrfx 		: di %5.3f _b[inter]
local se_yrfx		: di %5.3f _se[inter]

*Remove county and time fixed effects
egen tmp = mean(doc_ctyfx), by(year)
g doc_ctyfx_yrfx = doc_ctyfx-tmp
drop tmp
sum doc
xi: xtreg doc post yr_st inter i.year if treatment == 1, fe
local b_ctyfx_yrfx 		: di %5.3f _b[inter]
local se_ctyfx_yrfx		: di %5.3f _se[inter]

collapse (mean) doc* (count) count=doc, by(treatment yr_st)
drop if count<10

*Restore the underlying level
sum doc
g level = `r(mean)'
foreach var in doc_ctyfx doc_yrfx doc_ctyfx_yrfx {
	sum `var'
	replace `var' = `var'+(level-`r(mean)')
}

foreach var in doc doc_ctyfx doc_yrfx doc_ctyfx_yrfx {
	if "`var'" == "doc" {
		local sub "Raw Data"
		local beta  `b_base'
		local error `se_base'
		local y1 .78
		local y2 .75
		local x1 2.5
		local x2 4.3
	}
	
	if "`var'" == "doc_ctyfx" {
		local sub "County Fixed Effects"
		local beta  `b_ctyfx'
		local error `se_ctyfx'
		local y1 .9
		local y2 .892
		local x1 2.5
		local x2 4.3
	}
	
	if "`var'" == "doc_yrfx" {
		local sub "Annual Between Effects"
		local beta  `b_yrfx'
		local error `se_yrfx'
		local y1 .78
		local y2 .75
		local x1 2.5
		local x2 4.3
	}
	
	if "`var'" == "doc_ctyfx_yrfx" {
		local sub "County Fixed Effects and Annual Between Effects"
		local beta  `b_ctyfx_yrfx'
		local error `se_ctyfx_yrfx'
		local y1 .99
		local y2 .982
		local x1 2.5
		local x2 4.3
	}
	
	twoway ///
		scatter `var' yr_st if treatment == 1, || ///
		lfit `var' yr_st if treatment == 1 & yr_st<0, lcolor(navy) || ///
		lfit `var' yr_st if treatment == 1 & yr_st>=0, lcolor(navy) ///
		xline(-.5, lpattern(dash) lcolor(maroon)) ///
		title(" ") ///
		ytitle("Doctors Per 1000 Residents") ///
		xtitle("Year Relative to Designation") xmtick(##5) ///
		text(`y1' `x1' "Change in Slope: `beta'") ///
		text(`y2' `x2' "(`error')") ///
		legend(off)
	graph export "${root}/results/figures/treat_`var'.pdf", replace
	project, creates("${root}/results/figures/treat_`var'.pdf") preserve

	if "`var'" != "doc_ctyfx_yrfx" & "`var'" != "doc_yrfx" {
		twoway ///
			scatter `var' yr_st if treatment == 0, || ///
			lfit `var' yr_st if treatment == 0, lcolor(navy) ///
			title(" ") ///
			ytitle("Doctors Per 1000 Residents") ///
			xtitle("Year Relative to Designation") ///
			legend(off)
		graph export "${root}/results/figures/control_`var'.pdf", replace
		project, creates("${root}/results/figures/control_`var'.pdf") preserve
	}
}

restore
preserve

*---------------------------------------------------------------------
*National Trend in Doctor Counts and Maps
*---------------------------------------------------------------------

collapse (mean) doc (count) count=doc, by(year rural)
drop if count<10
tempfile full
save `full', replace
collapse (mean) doc (sum) count, by(year)
drop if count<10
append using `full'

twoway ///
	scatter doc year if rural==0, mcolor(none) || ///
	lfit doc year if rural==0, lcolor(none) || ///
	scatter doc year if rural==1, mcolor(none) || ///
	lfit doc year if rural==1, lcolor(none) || ///
	scatter doc year if rural==., mcolor(gs6) || ///
	lfit doc year if rural==., lcolor(gs6) ///
	title(" ") ///
	ytitle("Doctors Per 1000 Residents") ///
	ylabel(1(.25)2.25) ymtick(##2) yscale(range(1 2.25)) ///
	xlabel(2007(1)2014) ///
	xtitle("Year") ///
	legend(order(5 "National") ///
		row(1))
graph export "${root}/results/figures/national_doc_a.pdf", replace
project, creates("${root}/results/figures/national_doc_a.pdf") preserve

twoway ///
	scatter doc year if rural==0, || ///
	lfit doc year if rural==0, lcolor(navy) || ///
	scatter doc year if rural==1, mcolor(maroon) || ///
	lfit doc year if rural==1, lcolor(maroon) || ///
	scatter doc year if rural==., mcolor(gs6) || ///
	lfit doc year if rural==., lcolor(gs6) ///
	title(" ") ///
	ytitle("Doctors Per 1000 Residents") ///
	ylabel(1(.25)2.25) ymtick(##2) yscale(range(1 2.25)) ///
	xlabel(2007(1)2014) ///
	xtitle("Year") ///
	legend(order(5 "National" 1 "Non-Rural" 3 "Rural") ///
		row(1))
graph export "${root}/results/figures/national_doc_b.pdf", replace
project, creates("${root}/results/figures/national_doc_b.pdf") preserve

restore

*---------------------------------------------------------------------
*National State Level Maps
*---------------------------------------------------------------------
replace doc = doc*10

preserve
collapse (mean) doc [w=pop], by(statename year)
*State level maps
xtile tmp=doc, nq(6)
egen tmp2 = min(doc), by(tmp)
g cuts = .
forvalues i = 1/6 {
	sum tmp2 if tmp == `i'
	replace cuts = `r(mean)' in `i'
}
sum cuts if _n == 1
local bottom 	: di %5.1f `r(mean)'

sum cuts if _n == 6
local top 	: di %5.1f `r(mean)'

foreach yr in 2007 2009 2011 2012 2013 2014 {
	maptile doc if year == `yr', ///
		geography(state) ///
		geoid(statename) ///
		legdecimals(1) ///
		ndfcolor(maroon) ///
		cutpoints(cuts) ///
		rangecolor("`lightcolor'" "`darkcolor'") ///
		revcolor ///
		twopt( legend(lab(2 "<`bottom'") lab(8 ">`top'")) ///
		title(" "))
	graph export "${root}/results/figures/doc_dens_st_`yr'.pdf", replace
	project, creates("${root}/results/figures/doc_dens_st_`yr'.pdf") preserve

}

restore

*---------------------------------------------------------------------
*National County Level Maps
*---------------------------------------------------------------------

preserve

*Generate invariant map cut points
xtile tmp=doc, nq(6)
egen tmp2 = min(doc), by(tmp)
g cuts = .
forvalues i = 1/6 {
	sum tmp2 if tmp == `i'
	replace cuts = `r(mean)' in `i'
}
sum cuts if _n == 1
local bottom 	: di %5.1f `r(mean)'

sum cuts if _n == 6
local top 	: di %5.1f `r(mean)'

foreach yr in 2007 2009 2011 2012 2013 2014 {
	maptile doc if year == `yr', ///
		geography(county2000) ///
		legdecimals(1) ///
		stateoutline(*.28) ///
		ndfcolor(maroon) ///
		cutpoints(cuts) ///
		rangecolor("`lightcolor'" "`darkcolor'") ///
		revcolor ///
		twopt( legend(lab(2 "<`bottom'") lab(8 ">`top'")) ///
		title(" "))
	graph export "${root}/results/figures/doc_dens_cty_`yr'.pdf", replace
	project, creates("${root}/results/figures/doc_dens_cty_`yr'.pdf") preserve
}

restore

*---------------------------------------------------------------------
*National CZ Level Maps
*---------------------------------------------------------------------
preserve

*Generate invariant map cut points
collapse (mean) doc [w=pop], by(year cz)
xtile tmp=doc, nq(6)
egen tmp2 = min(doc), by(tmp)
g cuts = .
forvalues i = 1/6 {
	sum tmp2 if tmp == `i'
	replace cuts = `r(mean)' in `i'
}
sum cuts if _n == 1
local bottom 	: di %5.1f `r(mean)'

sum cuts if _n == 6
local top 	: di %5.1f `r(mean)'

foreach yr in 2007 2009 2011 2012 2013 2014 {
	maptile doc if year == `yr', ///
		geography(cz) ///
		legdecimals(1) ///
		stateoutline(*.28) ///
		ndfcolor(maroon) ///
		cutpoints(cuts) ///
		rangecolor("`lightcolor'" "`darkcolor'") ///
		revcolor ///
		twopt( legend(lab(2 "<`bottom'") lab(8 ">`top'")) ///
		title(" "))
	graph export "${root}/results/figures/doc_dens_cz_`yr'.pdf", replace
	project, creates("${root}/results/figures/doc_dens_cz_`yr'.pdf") preserve
}

