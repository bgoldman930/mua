/***
Purpose: Create covariates panel
***/

* load tract covariates
use ${root}/data/covariates/tract_covariates, clear
keep state county tract year pop share_senior poor_share
drop if year==1980
collapse (mean) share_senior poor_share (rawsum) pop [w=pop], by(state county year)
gen st = string(state,"%02.0f")
gen cty = string(county,"%03.0f")
rename county county2
gen county = st+cty
drop st cty state county2
destring county, replace
xtset county year
tsfill
order county year
by county: ipolate share_senior year, gen(share_senior_ip) 
by county: ipolate poor_share year, gen(poor_share_ip) 
by county: ipolate pop year, gen(pop_ip) 
drop share_seniors poor_share pop
gen county2 = string(county, "%05.0f")
drop county
rename county2 county
save ${root}/data/covariates/county_covariates_interpolated, replace




* add IMU score to interpolated covariates
use ${root}/data/covariates/ahrf_covariates, clear 
keep state county inf_mort_*
rename inf_mort_1996 inf_mort_1996
rename inf_mort_2001 inf_mort_2001
rename inf_mort_2002 inf_mort_2002
rename inf_mort_2003 inf_mort_2003
rename inf_mort_2004 inf_mort_2004
rename inf_mort_2005 inf_mort_2005
rename inf_mort_2006 inf_mort_2006
rename inf_mort_2007 inf_mort_2007
rename inf_mort_2008 inf_mort_2008
rename inf_mort_2009 inf_mort_2009
rename inf_mort_2010 inf_mort_2010
reshape long inf_mort_, i(state county) j(year)
merge 1:1 state county year using ${root}/data/covariates/county_infmort
keep if year>1989
drop _merge
drop deaths* births* inf_mort_1968
replace inf_mort=inf_mort*1000
replace inf_mort_1979=inf_mort_1979*1000
replace inf_mort_1999=inf_mort_1999*1000
replace inf_mort_=inf_mort if inf_mort_==.
replace inf_mort_=inf_mort_1999_2016 if inf_mort_==. & year>1998
replace inf_mort_=(0.7*inf_mort_1999_2016+0.3*inf_mort_1979_1998) if inf_mort_==. & year<=1998 //note this is BS
sort state county year
by state county: ipolate inf_mort_ year, gen(inf_mort_ip) epolate
replace inf_mort_ip=0 if inf_mort_ip<0
keep state county year inf_mort_ip
gen st = string(state,"%02.0f")
gen cty = string(county,"%03.0f")
rename county county2
gen county = st+cty
drop st cty state county2
drop if year>2010
merge 1:1 county year using ${root}/data/covariates/county_covariates_interpolated
destring county, replace
xtset county year
tsfill
drop _merge

* predict IMU scores
replace share_senior=100*share_senior
replace poor_share=100*poor_share

* recode poor_share
recode poor_share (0/2=24.6)   (2/4=23.7)   (4/6=22.8)   (6/8=21.9) ///
				  (8/10=21.0)  (10/12=20.0) (12/14=18.7) (14/16=17.4) ///
				  (16/18=16.2) (18/20=14.9) (20/22=13.6) (22/24=12.2) ///
				  (24/26=10.9) (26/28=9.3)  (28/30=7.8)  (30/32=6.6) ///
				  (32/34=5.6)  (34/36=4.7)  (36/38=3.4)  (38/40=2.1) ///
				  (40/42=1.3)  (42/44=1.0)  (44/46=0.7)  (46/48=0.4) ///
				  (48/50=0.1)  (50/100=0), gen(poor_share_imu)	
				  
replace poor_share_imu=25.1 if poor_share_ip==0

* recode share_senior
recode share_senior (0/7=20.2)   (7/8=20.1)   (8/9=19.9)   (9/10=19.8) ///
				    (10/11=19.6) (11/12=19.4) (12/13=19.1) (13/14=18.9) ///
				    (14/15=18.7) (15/16=17.8) (16/17=16.1) (17/18=14.4) ///
				    (18/19=12.8) (19/20=11.1) (20/21=9.8)  (21/22=8.9) ///
				    (22/23=8.0)  (23/24=7.0)  (24/25=6.1)  (25/26=5.1) ///
				    (26/27=4.0)  (27/28=2.8)  (28/29=1.7)  (29/30=0.6) ///
				    (30/100=0), gen(share_senior_imu)	
				  
* recode infant mortality
recode inf_mort     (0/8=26.0)   (8/9=25.6)   (9/10=24.8)   (10/11=24.0) ///
				    (11/12=23.2) (12/13=22.4) (13/14=21.5)  (14/15=20.5) ///
				    (15/16=19.5) (16/17=18.5) (17/18=17.5)  (18/19=16.4) ///
				    (19/20=15.3) (20/21=14.2) (21/22=13.1)  (22/23=11.9) ///
				    (23/24=10.8) (24/25=9.6)  (25/26=8.5)   (26/27=7.3) ///
				    (27/28=6.1)  (28/29=5.4)  (29/30=5.0)   (30/31=4.7) ///
					(31/32=4.3)  (32/33=4.0)  (33/34=3.6)   (34/35=3.3) ///
					(35/36=3.0)  (36/37=2.6)  (37/39=2.0)   (39/41=1.4) ///
					(41/43=0.8)  (43/45=0.2)  (45/100=0), gen(inf_mort_imu)	
					

gen predicted_imu_raw=poor_share_imu+share_senior_imu+inf_mort_imu
gen predicted_imu =   -5.40022 +   1.136819*predicted_imu_raw
order county year share_senior_ip poor_share_ip inf_mort_ip predicted_imu
keep county year share_senior_ip poor_share_ip inf_mort_ip predicted_imu
gen county2 = string(county, "%05.0f")
drop county
rename county2 county
save ${root}/data/covariates/county_covariates_interpolated_imu, replace


* now do a match

use "${root}/data/derived/mua_base", clear
keep if desig_level=="cty"
keep state county year imu 
gen st = string(state,"%02.0f")
gen cty = string(county,"%03.0f")
rename county county2
gen county = st+cty
drop st cty state county2
tempfile temp
save `temp'

use "${root}/data/derived/ama_county_data", clear
destring county, replace
xtset county year
tsfill
gen county2 = string(county,"%05.0f")
drop county
rename county2 county
order county
merge 1:1 county year using ${root}/data/covariates/county_covariates_interpolated_imu
drop if _merge==2
drop _merge
merge 1:1 county year using `temp'
drop if _merge==2
gen desig = (imu!=.)
replace desig = year if desig==1
bys county: egen designation_year=max(desig)
replace designation_year=. if designation_year==0
bys county: gen treated=(designation_year!=.)
drop desig _merge
tempfile temp
save `temp'

* save control counties
keep if treated==0
gen st = substr(county,1,2)
gen cty = substr(county, 3,3)
keep st year cty predicted_imu
rename cty cty_ctrl
rename predicted_imu imu_ctrl 
tempfile temp2
save `temp2'


* now, for each place that got treated, find a place in the same state that did not get treated
* then run a diff-in-diff 
use `temp', clear
keep county year imu predicted_imu designation_year treated 
keep if treated==1 & year==designation_year
gen st = substr(county,1,2)
gen cty = substr(county, 3,3)
order st cty county year
merge m:m st year using `temp2'
order st cty
sort st cty
keep if _merge==3
gen imudiff = abs(predicted_imu-imu_ctrl)
gsort county imudiff
bys county: gen count=_n
keep if count==1
keep st cty_ctrl year 
rename cty_ctrl cty
gen county=st+cty
order county year
keep county year
sort county year
bys county year: gen count=_n
drop if count>1
save ${root}/data/covariates/control_counties, replace


* now run event study with control counties

use ${root}/data/derived/ama_county_data, clear
destring county, replace
xtset county year
tsfill
gen county2 = string(county,"%05.0f")
drop county
rename county2 county
order county
merge 1:1 county year using ${root}/data/covariates/control_counties
gen desig = (count!=.)
replace desig = year if desig==1
bys county: egen designation_year=max(desig)
replace designation_year=. if designation_year==0
bys county: gen treated=(designation_year!=.)
drop desig _merge
keep if treated==1
keep if designation_year>1993 & designation_year<2010
replace treated=-1 if treated==1
save ${root}/data/covariates/control_counties_panel, replace
by county: ipolate tot year, gen(tot_ip) 

*A
gen eit = (year==designation_year)
gen lndocs = ln(tot)

*B
encode county, gen(countycode)
tsset countycode year
save temp, replace
gen binpre = (year-designation_year <= -6)
gen binpost = (year-designation_year >= 6)
reg lndocs binpre l(-5/-2).eit l(0/5).eit binpost i.year, absorb(county) cluster(county)

*C 
regsave, ci
gen t = _n - 7
replace t = t+1 if _n>=6
drop if _n>12
twoway (scatter coef t) ///
(line ci_lower t) ///
(line ci_upper t)

twoway (scatter coef t) ///
(rcap ci_upper ci_lower t), ///
ylab(-.3(.1).3)
*graph export ${root}/data/covariates/event_study_control.pdf, replace



* event study with treated counties 

* RUN EVENT STUDIES AT COUNTY LEVEL
use ${root}/data/derived/mua_base, clear
keep if desig_level=="cty"
keep state county year imu 
gen st = string(state,"%02.0f")
gen cty = string(county,"%03.0f")
rename county county2
gen county = st+cty
drop st cty state county2
tempfile temp
save `temp'


use ${root}/data/derived/ama_county_data, clear
destring county, replace
xtset county year
tsfill
gen county2 = string(county,"%05.0f")
drop county
rename county2 county
order county
merge 1:1 county year using ${root}/data/covariates/county_covariates_interpolated
drop if _merge==2
drop _merge
merge 1:1 county year using `temp'
drop if _merge==2
gen desig = (imu!=.)
replace desig = year if desig==1
bys county: egen designation_year=max(desig)
replace designation_year=. if designation_year==0
bys county: gen treated=(designation_year!=.)
drop desig _merge
keep if treated==1
keep if designation_year>1993 & designation_year<2010
save ${root}/data/covariates/treated_counties_panel, replace
by county: ipolate tot year, gen(tot_ip) 
by county: ipolate pop_ip year, gen(pop_ip2) epolate

*A
gen eit = (year==designation_year)
gen lndocs = ln(tot)
gen docs_per_capita = 1000*(tot/pop_ip2)
gen lndocs_pc = ln(docs_per_capita)


*B
encode county, gen(countycode)
tsset countycode year
save temp, replace
gen binpre = (year-designation_year <= -6)
gen binpost = (year-designation_year >= 6)
reg lndocs_pc binpre l(-5/-2).eit l(0/5).eit binpost i.year, absorb(county) cluster(county)

*C 
regsave, ci
gen t = _n - 7
replace t = t+1 if _n>=6
drop if _n>12
twoway (scatter coef t) ///
(line ci_lower t) ///
(line ci_upper t)

twoway (scatter coef t) ///
(rcap ci_upper ci_lower t), ///
ylab(-.3(.1).3)
*graph export ${root}/data/covariates/event_study_treatment.pdf


* now run a difference in difference regression with treated versus control counties

use ${root}/data/covariates/treated_counties_panel, clear
append using ${root}/data/covariates/control_counties_panel
keep county year tot designation_year treated
replace treated=0 if treated==-1

*A
gen eit = (year==designation_year)
gen lndocs = ln(tot)

*B
gen event_time = year-designation_year
gen post = (year>designation_year)
gen did = post*treated
reg lndocs event_time treated did

* create tables with treatment and control characteristics

use ${root}/data/covariates/treated_counties_panel, clear
append using ${root}/data/covariates/control_counties_panel
replace treated=0 if treated==-1
sort county year
by county: ipolate tot year, gen(tot_ip) 
by county: ipolate totpc year, gen(totpc_ip) 
keep if year==designation_year
keep county year tot_ip totpc_ip treated 
merge 1:1 county year using ${root}/data/covariates/county_covariates_interpolated_imu
drop if _merge==2
drop _merge
sort treated
by treated: sum tot_ip totpc_ip pred poor share inf_mort



/*

use /Users/Kaveh/Dropbox/mua/raw/ama/ama_county_data, clear
destring county, replace
xtset county year
tsfill
gen county2 = string(county,"%05.0f")
drop county
rename county2 county
order county
merge 1:1 county year using ${root}/data/covariates/county_covariates_interpolated
drop if _merge==2
