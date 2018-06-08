set more off 

/*

This file runs event studies for mortality.

*/

* load mortality data
use ${root}/data/derived/county_mortality_data, clear

* keep relevant variables
keep if sex=="Both"
keep fips cause_id year_id mx 
reshape wide mx, i(fips year_id) j(cause_id)

*keep if cause_name=="All causes" & sex=="Both"

gen 	county = string(fips,"%05.0f")
drop	fips
order	county
rename	year_id year
save	temp, replace

* load mua panel
use 	${root}/data/derived/mua_panel_allgeo, clear
keep	county year designation_year desig_level 
merge	1:1 county year using temp
keep	if _merge==3

* keep only designated counties with at least 3 pre-years and at least 6 post-years 
* also keep non-designated counties
keep	if (designation_year>1993 & designation_year<2010) | designation_year==.

* create indicator for year==designation_year
tab 	year
gen 	eit = (year==designation_year) if mx294!=.
tab 	year if eit==1

* create logged versions of deaths
gen 	lnmx294 = ln(mx294) // all causes
gen 	lnmx295 = ln(mx295) // communicable, maternal, neonatal, nutritional
gen 	lnmx296 = ln(mx296) // hiv and tb
gen 	lnmx366 = ln(mx366) // maternal
gen 	lnmx380 = ln(mx380) // neonatal
gen 	lnmx409 = ln(mx409) // noncommunicable
gen 	lnmx491 = ln(mx491) // cvd
gen 	lnmx508 = ln(mx508) // chronic respiratory
gen 	lnmx521 = ln(mx521) // cirrhosis and liver
gen 	lnmx558 = ln(mx558) // mental and substance abuse
gen 	lnmx586 = ln(mx586) // diabetes
gen 	lnmx687 = ln(mx687) // injuries
gen 	lnmx717 = ln(mx717) // self-harm and interpersonal

* make into a panel
encode	county, gen(countycode)
tsset 	countycode year

* create variable for being treated
gen		treated = (designation_year!=.)
tab 	year if treated==1

* keep only when outcome is nonmissing
keep 	if mx294!=.
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

* create the dummies
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

* run the regression for different types of mortality
reg 	lnmx296 binpre4 bn4 bn3 bn2 eit bp1 bp2 bp3 bp4 bp5 bp6 binpost6 i.year, absorb(county) cluster(county)
reg 	lnmx366 binpre4 bn4 bn3 bn2 eit bp1 bp2 bp3 bp4 bp5 bp6 binpost6 i.year, absorb(county) cluster(county)
reg 	lnmx380 binpre4 bn4 bn3 bn2 eit bp1 bp2 bp3 bp4 bp5 bp6 binpost6 i.year, absorb(county) cluster(county)
reg 	lnmx508 binpre4 bn4 bn3 bn2 eit bp1 bp2 bp3 bp4 bp5 bp6 binpost6 i.year, absorb(county) cluster(county)
reg 	lnmx521 binpre4 bn4 bn3 bn2 eit bp1 bp2 bp3 bp4 bp5 bp6 binpost6 i.year, absorb(county) cluster(county)
reg 	lnmx558 binpre4 bn4 bn3 bn2 eit bp1 bp2 bp3 bp4 bp5 bp6 binpost6 i.year, absorb(county) cluster(county)
reg 	lnmx586 binpre4 bn4 bn3 bn2 eit bp1 bp2 bp3 bp4 bp5 bp6 binpost6 i.year, absorb(county) cluster(county)
reg 	lnmx687 binpre4 bn4 bn3 bn2 eit bp1 bp2 bp3 bp4 bp5 bp6 binpost6 i.year, absorb(county) cluster(county)
reg 	lnmx717 binpre4 bn4 bn3 bn2 eit bp1 bp2 bp3 bp4 bp5 bp6 binpost6 i.year, absorb(county) cluster(county)


* run the regression for all-cause mortality
reg 	lnmx294 binpre4 bn4 bn3 bn2 eit bp1 bp2 bp3 bp4 bp5 bp6 binpost6 i.year, absorb(county) cluster(county)

* make the graph
regsave, ci
keep if _n>=1 & _n<=13
gen time = _n-6
replace time = time+1 if _n>=5
replace time = -1 if _n==13
sort time
twoway (scatter coef t, mcolor(black)) (rcap ci_upper ci_lower t, lcolor(gs10)), xline(-1, lcolor(gs5)) legend(off) xtitle("Event time years") ytitle("log mortality") 	xlabel(-5(1)7) 

* save the graph
graph export 	${root}/results/figures/event_mortality.pdf, replace

