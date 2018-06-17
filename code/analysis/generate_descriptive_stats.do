set more off 

/*

This file creates several descriptive graphs used in the slides

*/


* OECD DOCTORS PER CAPITA GRAPH
insheet using ${root}/data/raw/oecd/docspercapita2013.csv, comma clear
keep 	country value
gsort	-value
graph 	hbar (asis) value, over(country, sort(value) descending label(labsize(small))) title("Physicians per 1,000 population (2013)", size(medsmall)) ylab(, labsize(small))
graph 	export 	${root}/results/figures/oecd.pdf, replace


* HISTOGRAM OF DOCS PER CAPITA GRAPHS 
use 	${root}/data/covariates/ahrf_covariates.dta, clear
gen 	docspc = 1000*total_mds_2015/pop_2015
sum		docspc [w=pop_2015]
keep	state county docspc pop_2015 total_mds_2015 

* big support
hist	docspc if docspc<15, freq width(0.2) fcolor(none) lcolor(black) ylab(,nogrid) xtitle("Doctors per 1,000 residents")
graph 	export ${root}/results/figures/docspchist.pdf, replace

* small support
hist	docspc if docspc<5, freq width(0.1) fcolor(none) lcolor(black) ylab(0(100)300,nogrid) xtitle("Doctors per 1,000 residents")
graph 	export ${root}/results/figures/docspchist2.pdf, replace



* HOW MANY PLACES WERE DESIGNATED?

* load mua panel
use 	${root}/data/derived/mua_panel_allgeo, clear

* calculate number of places
keep 	if year==2015
gen 	treated=1 if desig_level!=""
tab 	treated desig_level

* 2. HISTOGRAM OF DESIGNATION YEAR
hist 	designation_year, freq fcolor(none) lcolor(black) ///
		title("Histogram of MUA designation year", size(medsmall) color(black)) ///
		ylab(,nogrid) xlab(1990(5)2015,) xtitle("Year")
graph export 	${root}/results/figures/histogram_designation_year.pdf, replace


* 3. MAP OF TREATED PLACES
keep 		if treated==1
destring 	county, replace
replace 	treated=10 if desig_level=="tract"
replace 	treated=20 if desig_level=="mcd"
maptile 	treated, geo(county1990) ndfcolor(white) fcolor(Accent) twopt(legend(lab(1 "Not Designated") lab(2 "County") lab(3 "MCD") lab(4 "Tract")))
graph 		export 	${root}/results/figures/mua_map.pdf, replace

* HISTOGRAM OF IMU SCORES

* load file
use 	${root}/data/derived/mua_base, clear
keep 	if year>1990 & year<2016
replace imu=. if imu==0
hist 	imu, freq fcolor(none) lcolor(black) xline(62.0, lcolor(red)) ///
		title("Histogram of IMU scores", size(medsmall) color(black)) ///
		ylab(,nogrid) xlab(0(20)100,) xtitle("IMU score")
graph export 	${root}/results/figures/imu.pdf, replace


/*
* 1990 
cd		/Users/Kaveh/Desktop
use 	mua_panel_allgeo, clear
keep 	if year==1991
replace	year=1990 if year==1991
save	temp, replace

use 	"/Users/Kaveh/GitHub/mua/data/covariates/tract_covariates.dta", clear
keep 	if year==1990
collapse (mean) share_senior popdensity hhinc_mean poor_share black_share hisp_share asian_share singleparent_share median_rent foreign_share household_size divorced_share married_share median_value lfp lfp_m lfp_w pct_manufacturing lead_share frac_kids_eng_only frac_kids_span nohs_share nohs_male_share nohs_female_share college_share college_male_share college_female_share share_innercity share_outercity share_rural share_owner share_renter student_teacher_ grad_4year grad_5year dropout poor_share_white poor_share_black poor_share_asian poor_share_hispanic med_hhinc_white med_hhinc_black med_hhinc_asian med_hhinc_hispanic (rawsum) pop [w=pop], by(state county)
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop	st state cty county2
order	county
merge	1:1 county using temp
gen 	treated = (desig_level!="")
*sum		share_senior popdensity hhinc_mean poor_share black_share hisp_share asian_share singleparent_share median_rent foreign_share household_size divorced_share married_share median_value college_share share_rural if treated==1
sum		share_senior popdensity hhinc_mean poor_share black_share hisp_share asian_share singleparent_share median_rent foreign_share household_size divorced_share married_share median_value college_share share_rural if treated==1 & desig_level=="cty"
*sum		share_senior popdensity hhinc_mean poor_share black_share hisp_share asian_share singleparent_share median_rent foreign_share household_size divorced_share married_share median_value college_share share_rural if treated==1 & desig_level=="mcd"
*sum		share_senior popdensity hhinc_mean poor_share black_share hisp_share asian_share singleparent_share median_rent foreign_share household_size divorced_share married_share median_value college_share share_rural if treated==1 & desig_level=="tract"
sum		share_senior popdensity hhinc_mean poor_share black_share hisp_share asian_share singleparent_share median_rent foreign_share household_size divorced_share married_share median_value college_share share_rural if treated==0





