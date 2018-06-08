set more off 

/*

This file runs event studies on (# of doctors) using the panels created in create_panels.do.

Note that it tries out several different samples / specifications.  I first run the main specification, then the others.

*/

**********************
* MAIN SPECIFICATION *
**********************

* note:
* the main specification is run at the county level.
* it includes all counties ever treated at any geographical level - i.e., a county is considered treated even if it had a single census tract within it treated.

* load mua panel
use 	${root}/data/derived/mua_panel_allgeo, clear

* drop years with no doctor data
drop	if tot==.
tab		year 

* since only have doctor data in odd years, make it so that all places were designated in odd years
gen 	des2=designation_year+1-mod(designation_year,2)
tab 	designation_year des2
tab		des2

* keep only designated counties with at least 2 pre-years (4 years pre) and at least 4 post-years (8 years post)
* also keep non-designated counties
keep	if (des2>1993 & des2<2009) | des2==.

* create indicator for year==designation_year
tab 	year
gen 	eit = (year==des2) if totpc!=.
tab 	year if eit==1

* create logged versions of doctors
gen 	lndocs = ln(totpc)
gen 	lndocs2 = ln(tot) 

* create logged versions of doctors per capita
gen		lndocspc = ln(totpc/pop_ep)
gen		lndocspc2 = ln(tot/pop_ep)

* make into a panel
encode	county, gen(countycode)
tsset 	countycode year

* create variable for being treated
gen		treated = (des2!=.)
tab 	year if treated==1

* keep only when outcome is nonmissing
keep 	if lndocs!=.
tab 	year if treated==1

*Keep only counties with information for the whole sample
egen 	N=count(year), by(county)
tab 	N
br 		if N==2
tab 	year if N==12
tab 	N treated
keep	if N==13
tab 	year if treated==1
drop	N

*Confirm that the whole window is contained in the data for each county
gen 	dist=year-des2
egen 	mind=min(dist),by(county)
egen 	maxd=max(dist),by(county)
tab1 	mind maxd if dist==0

gen 	binpre4 = (year-des2 < -4) 
gen 	binpost8 = (year-des2 > 8) & (year-des2 !=.)

replace binpre4=0 if binpre4==.
replace binpost8=0 if binpost8==.

gen 	bn6=year-des2==-6
gen 	bn4=year-des2==-4
gen 	bn2=year-des2==-2
gen 	bp2=year-des2==2
gen 	bp4=year-des2==4
gen 	bp6=year-des2==6
gen 	bp8=year-des2==8


tab1 	b*
tab 	year if treated==1

* save file
save temp, replace


* run regressions 
reg 	lndocs binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocs binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	lndocs2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocs2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	totpc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	totpc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	tot binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	tot binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	lndocspc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocspc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	lndocspc2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocspc2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)


* regress log doctors per capita (including never treated)
use temp, clear
reg 	lndocspc2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
regsave, ci
keep if _n>=1 & _n<=9
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==9
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians per capita") 	xlabel(-6(2)10) 
graph export 	${root}/results/figures/event_doctors.pdf, replace
* note this is the same as county2_logdocspercapita_full below






************************
* OTHER SPECIFICATIONS *
************************

* ONE: RUN EVENT STUDY AT COUNTY LEVEL USING COUNTY-LEVEL MUAs, 1991-2015

* load mua panel
use 	${root}/data/derived/mua_panel, clear

* interpolate county population
sort	county year
by 		county: ipolate pop_ip year, gen(pop_ep) epolate

* drop places that were designated as ct or mcd level
drop 	if ct_or_mcd==1

* drop years with no doctor data
drop	if totpc==.
tab		year 

* make temporary correction (before acquiring 2001 data)
replace year=2001 if year==2000
 
* since only have doctor data in odd years, make it so that all places were designated in odd years
gen 	des2=designation_year+1-mod(designation_year,2)
tab 	designation_year des2
tab		des2

* keep only designated counties with at least 2 pre-years (4 years pre) and at least 4 post-years (8 years post)
* also keep non-designated counties
keep	if (des2>1993 & des2<2009) | des2==.

* create indicator for year==designation_year
tab 	year
gen 	eit = (year==des2) if totpc!=.
tab 	year if eit==1

* create logged versions of doctors
gen 	lndocs = ln(totpc)
gen 	lndocs2 = ln(tot) 

* create logged versions of doctors per capita
gen		lndocspc = ln(1000*totpc/pop_ep)
gen		lndocspc2 = ln(1000*tot/pop_ep)

* make into a panel
encode	county, gen(countycode)
tsset 	countycode year

* keep only when outcome is nonmissing
keep 	if lndocs!=.
tab 	year if treated==1

*Keep only counties with information for the whole sample
egen 	N=count(year), by(county)
tab 	N
br 		if N==2
tab 	year if N==12
tab 	N treated
keep	if N==13
tab 	year if treated==1
drop	N

*Confirm that the whole window is contained in the data for each county
gen 	dist=year-des2
egen 	mind=min(dist),by(county)
egen 	maxd=max(dist),by(county)
tab1 	mind maxd if dist==0

gen 	binpre4 = (year-des2 < -4) 
gen 	binpre6 = (year-des2 < -6) 
gen 	binpost8 = (year-des2 > 8) & (year-des2 !=.)

replace binpre6=0 if binpre6==.
replace binpre4=0 if binpre4==.
replace binpost8=0 if binpost8==.
gen 	bn6=year-des2==-6
gen 	bn4=year-des2==-4
gen 	bn2=year-des2==-2
gen 	b0=year-des2==0
gen 	bp2=year-des2==2
gen 	bp4=year-des2==4
gen 	bp6=year-des2==6
gen 	bp8=year-des2==8


tab1 	b*
tab 	year if treated==1

* save temporary version
save temp, replace
 
* regress log total doctors
reg 	lndocs binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocs binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	lndocs2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocs2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

* regress total doctors
reg 	totpc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	totpc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	tot  binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	tot binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

* regress log doctors per capita
reg 	lndocspc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocspc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	lndocspc2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocspc2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)


* regress log doctors per capita (including never treated)
use 	temp, clear
reg 	lndocspc2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
regsave, ci
keep 	if _n>=1 & _n<=9
gen 	time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==9
sort 	time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians per capita") 	xlabel(-6(2)10) 
*graph export 	${root}/results/figures/county_logdocspercapita_full.pdf, replace

* regress log primary care doctors per capita (including never treated)
use temp, clear
reg 	lndocspc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
regsave, ci
keep if _n>=1 & _n<=9
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==9
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians per capita") 	xlabel(-6(2)10) 
*graph export 	${root}/results/figures/county_logpcdocspercapita_full.pdf, replace

* regress log doctors per capita (treated only)
use temp, clear
reg 	lndocspc2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)
regsave, ci
keep if _n>=1 & _n<=9
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==9
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians per capita") 	xlabel(-6(2)10) 
*graph export 	${root}/results/figures/county_logdocspercapita_treated.pdf, replace

* regress log primary care doctors per capita (treated only)
use temp, clear
reg 	lndocspc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)
regsave, ci
keep if _n>=1 & _n<=9
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==9
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians per capita") 	xlabel(-6(2)10) 
*graph export 	${root}/results/figures/county_logpcdocspercapita_treated.pdf, replace


* TWO: RUN EVENT STUDY AT TRACT LEVEL, 2001-2015

* load mua panel
use 	${root}/data/derived/mua_panel_tract, clear

* drop years with no doctor data
drop	if tot==.
tab		year 
 
* since only have doctor data in odd years, make it so that all places were designated in odd years
gen 	des2=designation_year+1-mod(designation_year,2)
tab 	designation_year des2
tab		des2

* keep only designated counties with at least 2 pre-years (4 years pre) and at least 2 post-years (4 years post)
* also keep non-designated counties
keep	if (des2>2003 & des2<2011) | des2==.
tab 	des2

* create indicator for year==designation_year
tab 	year
gen 	eit = (year==des2) if tot!=.
tab 	year if eit==1

* create logged versions of doctors
gen 	ihsdocs = log(totpc + sqrt(totpc^2 + 1))
gen 	ihsdocs2 = log(tot + sqrt(tot^2 + 1))

/* NEED TO GET FULL POPULATION PANEL UP TO 2015 FOR THIS!
* create logged versions of doctors per capita
gen		lndocspc = ln(totpc/pop_ip)
gen		lndocspc2 = ln(tot/pop_ip)
*/

* make into a panel
destring tract, replace
tsset 	 tract year

* keep only when outcome is nonmissing
keep 	if ihsdocs2!=.

* create variable for being treated
gen		treated = (des2!=.)
tab 	year if treated==1

*Keep only counties with information for the whole sample
egen 	N=count(year), by(tract)
tab 	N
tab 	year if N==8
tab 	N treated
keep	if N==8
tab 	year if treated==1
drop	N

/*
*Confirm that the whole window is contained in the data for each county
gen 	dist=year-des2
egen 	mind=min(dist),by(county)
egen 	maxd=max(dist),by(county)
tab1 	mind maxd if dist==0
*/

gen 	binpre4 = (year-des2 < -4) 
gen 	binpost6 = (year-des2 > 6) & (year-des2 !=.)

replace binpre4=0 if binpre4==.
replace binpost6=0 if binpost6==.

gen 	bn4=year-des2==-4
gen 	bn2=year-des2==-2
gen 	bp2=year-des2==2
gen 	bp4=year-des2==4
gen 	bp6=year-des2==6

tab1 	b*
tab 	year if treated==1
 
* save temporary file
save temp, replace

* run regressions 

reg 	ihsdocs binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year, absorb(tract) cluster(tract)
reg 	ihsdocs binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year if treat==1, absorb(tract) cluster(tract)

reg 	ihsdocs2 binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year, absorb(tract) cluster(tract)
reg 	ihsdocs2 binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year if treat==1, absorb(tract) cluster(tract)

reg 	totpc binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year, absorb(tract) cluster(tract)
reg 	totpc binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year if treat==1, absorb(tract) cluster(tract)

reg 	tot binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year, absorb(tract) cluster(tract)
reg 	tot binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year if treat==1, absorb(tract) cluster(tract)

* reg log doctors (including never treated)
use temp, clear
reg 	ihsdocs2 binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year, absorb(tract) cluster(tract)
regsave, ci
keep if _n>=1 & _n<=8
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==8
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians") 	xlabel(-6(2)8) 
*graph export 	${root}/results/figures/tract_logdocs_full.pdf, replace


* reg log doctors (treated only)
use temp, clear
reg 	ihsdocs2 binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year if treat==1, absorb(tract) cluster(tract)
regsave, ci
keep if _n>=1 & _n<=8
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==8
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians") 	xlabel(-6(2)8) 
*graph export 	${root}/results/figures/tract_logdocs_treated.pdf, replace


* reg log primary care doctors (including never treated)
use temp, clear
reg 	ihsdocs binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year, absorb(tract) cluster(tract)
regsave, ci
keep if _n>=1 & _n<=8
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==8
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians") 	xlabel(-6(2)8) 
*graph export 	${root}/results/figures/tract_logpcdocs_full.pdf, replace



* reg log primary care doctors (including never treated)
use temp, clear
reg 	ihsdocs binpre4 bn4 eit bp2 bp4 bp6 binpost6 i.year if treat==1, absorb(tract) cluster(tract)
regsave, ci
keep if _n>=1 & _n<=8
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==8
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians") 	xlabel(-6(2)8) 
*graph export 	${root}/results/figures/tract_logpcdocs_treated.pdf, replace




* THREE: RUN EVENT STUDY AT COUNTY LEVEL USING MUAS DESIGNATED AT ANY LEVEL, 1991-2015

* load mua panel
use 	${root}/data/derived/mua_panel_allgeo, clear

* drop years with no doctor data
drop	if tot==.
tab		year 

* since only have doctor data in odd years, make it so that all places were designated in odd years
gen 	des2=designation_year+1-mod(designation_year,2)
tab 	designation_year des2
tab		des2

* keep only designated counties with at least 2 pre-years (4 years pre) and at least 4 post-years (8 years post)
* also keep non-designated counties
keep	if (des2>1993 & des2<2009) | des2==.

* create indicator for year==designation_year
tab 	year
gen 	eit = (year==des2) if totpc!=.
tab 	year if eit==1

* create logged versions of doctors
gen 	lndocs = ln(totpc)
gen 	lndocs2 = ln(tot) 

* create logged versions of doctors per capita
gen		lndocspc = ln(totpc/pop_ep)
gen		lndocspc2 = ln(tot/pop_ep)

* make into a panel
encode	county, gen(countycode)
tsset 	countycode year

* create variable for being treated
gen		treated = (des2!=.)
tab 	year if treated==1

* keep only when outcome is nonmissing
keep 	if lndocs!=.
tab 	year if treated==1

*Keep only counties with information for the whole sample
egen 	N=count(year), by(county)
tab 	N
br 		if N==2
tab 	year if N==12
tab 	N treated
keep	if N==13
tab 	year if treated==1
drop	N


*Confirm that the whole window is contained in the data for each county
gen 	dist=year-des2
egen 	mind=min(dist),by(county)
egen 	maxd=max(dist),by(county)
tab1 	mind maxd if dist==0

gen 	binpre4 = (year-des2 < -4) 
gen 	binpost8 = (year-des2 > 8) & (year-des2 !=.)

replace binpre4=0 if binpre4==.
replace binpost8=0 if binpost8==.

gen 	bn6=year-des2==-6
gen 	bn4=year-des2==-4
gen 	bn2=year-des2==-2
gen 	bp2=year-des2==2
gen 	bp4=year-des2==4
gen 	bp6=year-des2==6
gen 	bp8=year-des2==8


tab1 	b*
tab 	year if treated==1

* save file
save temp, replace

 
* run regressions 
reg 	lndocs binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocs binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	lndocs2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocs2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	totpc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	totpc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	tot binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	tot binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	lndocspc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocspc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)

reg 	lndocspc2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
reg 	lndocspc2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)


* regress log doctors per capita (including never treated)
use temp, clear
reg 	lndocspc2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
regsave, ci
keep if _n>=1 & _n<=9
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==9
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians per capita") 	xlabel(-6(2)10) 
* graph export 	${root}/results/figures/county2_logdocspercapita_full.pdf, replace


* regress log primary care doctors per capita (including never treated)
use temp, clear
reg 	lndocspc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)
regsave, ci
keep if _n>=1 & _n<=9
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==9
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians per capita") 	xlabel(-6(2)10) 
*graph export 	${root}/results/figures/county2_logpcdocspercapita_full.pdf, replace


* regress log doctors per capita (treated only)
use temp, clear
reg 	lndocspc binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)
regsave, ci
keep if _n>=1 & _n<=9
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==9
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians per capita") 	xlabel(-6(2)10) 
*graph export 	${root}/results/figures/county2_logdocspercapita_treated.pdf, replace


* regress log primary care doctors per capita (including never treated)
use temp, clear
reg 	lndocspc2 binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year if treat==1, absorb(county) cluster(county)
regsave, ci
keep if _n>=1 & _n<=9
gen time = _n-6
replace time = time+3 if _n>=3
replace time = time*2 if _n>=4
replace time = -6 if _n==1
replace time = -2 if _n==9
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-2, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log physicians per capita") 	xlabel(-6(2)10) 
*graph export 	${root}/results/figures/county2_logpcdocspercapita_treated.pdf, replace

* OTHER STUFF (SKETCHY)
* add interactions by geo
* add interaction by mcd
use 	temp, clear
gen		mcd = (desig_level=="mcd") if desig_level!=""
gen 	binpre4im=binpre4*mcd
gen 	binpost8im=binpost8*mcd
gen 	bn6im=bn6*mcd
gen 	bn4im=bn4*mcd
gen 	bn2im=bn2*mcd
gen 	bp2im=bp2*mcd
gen 	bp4im=bp4*mcd
gen 	bp6im=bp6*mcd
gen 	bp8im=bp8*mcd
gen		eitim=eit*mcd
* add interaction by tract
gen		tr = (desig_level=="tract") if desig_level!=""
gen 	binpre4it=binpre4*tr
gen 	binpost8it=binpost8*tr
gen 	bn6it=bn6*tr
gen 	bn4it=bn4*tr
gen 	bn2it=bn2*tr
gen 	bp2it=bp2*tr
gen 	bp4it=bp4*tr
gen 	bp6it=bp6*tr
gen 	bp8it=bp8*tr
gen		eitit=eit*tr
reg 	lndocspc2 binpre4 binpre4im binpre4it bn4 bn4im bn4it eit eitim eitit bp2 bp2im bp2it bp4 bp4im bp4it bp6 bp6im bp6it bp8 bp8im bp8it binpost8 binpost8im binpost8it i.year, absorb(county) cluster(county)
regsave, ci

lincom binpre4 + binpre4it
regsave, ci
lincom bn4 + bn4it
lincom eit + eitit
lincom bp2 + bp2it
lincom bp4 + bp4it
lincom bp6 + bp6it
lincom bp8 + bp8it
lincom binpost8 + binpost8it

lincom binpre4 + binpre4im
lincom bn4 + bn4im
lincom eit + eitim
lincom bp2 + bp2im
lincom bp4 + bp4im
lincom bp6 + bp6im
lincom bp8 + bp8im
lincom binpost8 + binpost8im

lincom binpre4 
lincom bn4 
lincom eit
lincom bp2 
lincom bp4
lincom bp6 
lincom bp8 
lincom binpost8 


/*

OLD CODE STASH

* FOUR: RUN CONTROL EVENT STUDY
* load mua panel
cd		/Users/Kaveh/Desktop
use 	mua_panel_allgeo, clear

* drop years with no doctor data
drop	if tot==.
tab		year 

* since only have doctor data in odd years, make it so that all places were designated in odd years
gen 	des2=designation_year+1-mod(designation_year,2)
tab 	designation_year des2
tab		des2

* keep only designated counties with at least 2 pre-years (4 years pre) and at least 4 post-years (8 years post)
* also keep non-designated counties
keep	if (des2>1993 & des2<2009) | des2==.

* create indicator for year==designation_year
tab 	year
gen 	eit = (year==des2) if totpc!=.
tab 	year if eit==1

* create logged versions of doctors
gen 	lndocs = ln(totpc)
gen 	lndocs2 = ln(tot) 

* create logged versions of doctors per capita
gen		lndocspc = ln(totpc/pop_ep)
gen		lndocspc2 = ln(tot/pop_ep)

* make into a panel
encode	county, gen(countycode)
tsset 	countycode year

* create variable for being treated
gen		treated = (des2!=.)
tab 	year if treated==1

* keep only when outcome is nonmissing
keep 	if lndocs!=.
tab 	year if treated==1

*Keep only counties with information for the whole sample
egen 	N=count(year), by(county)
tab 	N
br 		if N==2
tab 	year if N==12
tab 	N treated
keep	if N==13
tab 	year if treated==1
drop	N


*Confirm that the whole window is contained in the data for each county
gen 	dist=year-des2
egen 	mind=min(dist),by(county)
egen 	maxd=max(dist),by(county)
tab1 	mind maxd if dist==0

gen 	binpre4 = (year-des2 < -4) 
gen 	binpost8 = (year-des2 > 8) & (year-des2 !=.)

replace binpre4=0 if binpre4==.
replace binpost8=0 if binpost8==.

gen 	bn6=year-des2==-6
gen 	bn4=year-des2==-4
gen 	bn2=year-des2==-2
gen 	bp2=year-des2==2
gen 	bp4=year-des2==4
gen 	bp6=year-des2==6
gen 	bp8=year-des2==8


tab1 	b*
tab 	year if treated==1

* save file
save temp, replace

 
* run regressions 
reg 	lndocs binpre4 bn4 eit bp2 bp4 bp6 bp8 binpost8 i.year, absorb(county) cluster(county)

save ${root}/data/derived/treatment_control_pairs, replace


* add interaction for tract
use 	temp, clear
gen		tr = (desig_level=="tract") if desig_level!=""
gen 	binpre4i=binpre4*tr
gen 	binpost8i=binpost8*tr
gen 	bn6i=bn6*tr
gen 	bn4i=bn4*tr
gen 	bn2i=bn2*tr
gen 	bp2i=bp2*tr
gen 	bp4i=bp4*tr
gen 	bp6i=bp6*tr
gen 	bp8i=bp8*tr
gen		eiti=eit*tr
reg 	lndocspc2 binpre4 binpre4i bn4 bn4i eit eiti bp2 bp2i bp4 bp4i bp6 bp6i bp8 bp8i binpost8 binpost8i i.year, absorb(county) cluster(county)

* add interaction for mcd
use 	temp, clear
gen		mcd = (desig_level=="mcd") if desig_level!=""
gen 	binpre4i=binpre4*mcd
gen 	binpost8i=binpost8*mcd
gen 	bn6i=bn6*mcd
gen 	bn4i=bn4*mcd
gen 	bn2i=bn2*mcd
gen 	bp2i=bp2*mcd
gen 	bp4i=bp4*mcd
gen 	bp6i=bp6*mcd
gen 	bp8i=bp8*mcd
gen		eiti=eit*mcd
reg 	lndocspc2 binpre4 binpre4i bn4 bn4i eit eiti bp2 bp2i bp4 bp4i bp6 bp6i bp8 bp8i binpost8 binpost8i i.year, absorb(county) cluster(county)

lincomb

/*


* FOUR: RUN INTERPOLATED VERSION

* load mua panel
cd		/Users/Kaveh/Desktop
use 	mua_panel_allgeo, clear

* interpolate doctor counts
sort 	county year
by 		county: ipolate tot year, gen(tot_ep)
by 		county: ipolate totpc year, gen(totpc_ep)
drop 	tot totpc 

* keep only designated counties with at least 3 pre-years and at least 6 post-years 
* also keep non-designated counties
keep	if (designation_year>1993 & designation_year<2010) | designation_year==.

* create indicator for year==designation_year
tab 	year
gen 	eit = (year==designation_year) if tot_ep!=.
tab 	year if eit==1

* create logged versions of deaths
gen 	lntot = ln(10000*tot_ep/pop) // all doctors
gen 	lntotpc = ln(10000*totpc_ep/pop) // primary care doctors

* make into a panel
encode	county, gen(countycode)
tsset 	countycode year

* create variable for being treated
gen		treated = (designation_year!=.)
tab 	year if treated==1

* keep only when outcome is nonmissing
keep 	if lntot!=.
tab 	year if treated==1

/*
*Keep only counties with information for the whole sample
egen 	N=count(year), by(county)
tab 	N
br 		if N==2
tab 	year if N==12
tab 	N treated
keep	if N==13
tab 	year if treated==1
drop	N

*Confirm that the whole window is contained in the data for each county
gen 	dist=year-des2
egen 	mind=min(dist),by(county)
egen 	maxd=max(dist),by(county)
tab1 	mind maxd if dist==0
*/


gen 	binpre4 = (year-designation_year < -4) 
gen 	binpost6 = (year-designation_year > 6) & (year-designation_year !=.)
replace binpre4=0 if binpre4==.
replace binpost6=0 if binpost6==.

gen 	bn4=year-designation_year==-4
gen 	bn3=year-designation_year==-3
gen 	bn2=year-designation_year==-2
gen 	bn1=year-designation_year==-1

gen 	bp1=year-designation_year==1
gen 	bp2=year-designation_year==2
gen 	bp3=year-designation_year==3
gen 	bp4=year-designation_year==4
gen 	bp5=year-designation_year==5
gen 	bp6=year-designation_year==6

reg 	lntot binpre4 bn4 bn3 bn2 eit bp1 bp2 bp3 bp4 bp5 bp6 binpost6 i.year, absorb(county) cluster(county)
regsave, ci
keep if _n>=1 & _n<=13
gen time = _n-6
replace time = time+1 if _n>=5
replace time = -1 if _n==13
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-1, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log mortality") 	xlabel(-5(1)7) 






/*

* now run event study on control counties

* load mua panel
cd		/Users/Kaveh/Desktop
use 	mua_panel_allgeo, clear

* drop vars
drop	designation_year desig_level predicted
merge	m:1 county using ${root}/data/covariates/control_counties


* DIFFERENCE IN DIFFERENCE

* step 1: plot doctor density for all places designated in 1994 (just sum them together)
cd		/Users/Kaveh/Desktop
use 	mua_panel, clear

sort county year
by 		county: ipolate pop_ip year, gen(pop_ep) epolate

gen docs_per_capita= 1000*tot/pop_ep

keep if designation_year==2014
drop if year==2001
replace year=2001 if year==2000
collapse (mean) docs_per_capita [w=pop_ep], by(year)
drop if mod(year,2)==0
twoway connected docs_per_capita year

* step 2: plot doctor density for places not designated in 1994 similar on observables (use IMU score to match?)

