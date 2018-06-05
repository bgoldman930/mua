* event study

cd /Users/Kaveh/Dropbox/mua/raw/ama

set more off 

* RUN EVENT STUDIES AT COUNTY LEVEL
use /Users/Kaveh/GitHub/mua/data/derived/mua_base, clear
keep if desig_level=="cty"
keep state county year imu 
gen st = string(state,"%02.0f")
gen cty = string(county,"%03.0f")
rename county county2
gen county = st+cty
drop st cty state county2
tempfile temp
save `temp'

use ama_county_data, clear
replace tot=1.2*tot if year>=2000
destring county, replace
xtset county year
tsfill
gen county2 = string(county,"%05.0f")
drop county
rename county2 county
order county
merge 1:1 county year using `temp'
drop if _merge==2
gen desig = (imu!=.)
replace desig = year if desig==1
bys county: egen designation_year=max(desig)
replace designation_year=. if designation_year==0
bys county: gen treated=(designation_year!=.)
drop desig _merge
keep if treated==1
keep if designation_year>1993 & designation_year<2013

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
(rcap ci_upper ci_lower t)








* RUN EVENT STUDIES AT TRACT LEVEL
use /Users/Kaveh/GitHub/mua/data/derived/mua_base, clear
keep if desig_level=="tract"
keep state county tract year imu 
gen st = string(state,"%02.0f")
gen cty = string(county,"%03.0f")
gen tr = string(tract,"%06.0f")
rename tract tract2
gen tract = st+cty+tr
drop st cty tr state county tract2
tempfile temp
save `temp'


use ama_tract_data, clear
keep tract year tot
destring tract, replace
xtset tract year
tsfill
gen tract2 = string(tract,"%011.0f")
drop tract
rename tract2 tract
order tract year
merge 1:1 tract year using `temp'
drop if _merge==2
gen desig = (imu!=.)
replace desig = year if desig==1
bys tract: egen designation_year=max(desig)
replace designation_year=. if designation_year==0
bys tract: gen treated=(designation_year!=.)
drop desig _merge
keep if treated==1
keep if designation_year>1999

*  
gen eit = (year==designation_year)
gen lndocs = ln(tot)

*B
encode tract, gen(tractcode)
tsset tractcode year
save temp, replace
gen binpre = (year-designation_year <= -6)
gen binpost = (year-designation_year >= 6)
reg lndocs binpre l(-5/-2).eit l(0/5).eit binpost i.year, absorb(tract) cluster(tract)

*C 
regsave, ci
gen t = _n - 7
replace t = t+1 if _n>=6
drop if _n>12
twoway (scatter coef t) ///
(line ci_lower t) ///
(line ci_upper t)



* PREDICT IMU SCORES FOR ALL COUNTY-YEARS

* STEP 1: load all 2007 counties
use /Users/Kaveh/Dropbox/mua/raw/ama/ama_county_data, clear
rename county fips
gen state = substr(fips, 1, 2)
gen county = substr(fips, 3, 3)
destring state, replace
destring county, replace
drop fips
order state county
keep if year==2007

* STEP 2: generate IMU scores for each county

* merge in infant mortality data
merge 1:1 state county year using ${root}/data/covariates/county_infmort, keepusing(inf_mort inf_mort_1999_2016 inf_mort_1999_2016)
drop if _merge==2
drop _merge
replace inf_mort = inf_mort*1000
replace inf_mort_1999_2016 = inf_mort_1999_2016*1000
merge 1:1 state county using ${root}/data/covariates/ahrf_covariates, keepusing(inf_mort_*)
drop if _merge==2
drop _merge

* merge in poor_share data
merge 1:1 state county using ${root}/data/covariates/ahrf_covariates, keepusing(poor_share_2005 pop_2005)
drop if _merge==2
drop _merge
gen poor_share = poor_share_2005/pop_2005
replace poor_share=100*poor_share

* merge in senior_share data
merge 1:1 state county using ${root}/data/covariates/ahrf_covariates, keepusing(seniors_pop_2005 pop_2005 pop_2007)
drop if _merge==2
drop _merge
gen share_senior = seniors_pop_2005/pop_2005
replace share_senior = share_senior*100

* keep relevant variables
keep share_senior poor_share inf_mort_1996_2000 state county year  

* recode poor_share
recode poor_share (0/2=24.6)   (2/4=23.7)   (4/6=22.8)   (6/8=21.9) ///
				  (8/10=21.0)  (10/12=20.0) (12/14=18.7) (14/16=17.4) ///
				  (16/18=16.2) (18/20=14.9) (20/22=13.6) (22/24=12.2) ///
				  (24/26=10.9) (26/28=9.3)  (28/30=7.8)  (30/32=6.6) ///
				  (32/34=5.6)  (34/36=4.7)  (36/38=3.4)  (38/40=2.1) ///
				  (40/42=1.3)  (42/44=1.0)  (44/46=0.7)  (46/48=0.4) ///
				  (48/50=0.1)  (50/100=0), gen(poor_share_imu)	
				  
replace poor_share_imu=25.1 if poor_share==0

* recode share_senior
recode share_senior (0/7=20.2)   (7/8=20.1)   (8/9=19.9)   (9/10=19.8) ///
				    (10/11=19.6) (11/12=19.4) (12/13=19.1) (13/14=18.9) ///
				    (14/15=18.7) (15/16=17.8) (16/17=16.1) (17/18=14.4) ///
				    (18/19=12.8) (19/20=11.1) (20/21=9.8)  (21/22=8.9) ///
				    (22/23=8.0)  (23/24=7.0)  (24/25=6.1)  (25/26=5.1) ///
				    (26/27=4.0)  (27/28=2.8)  (28/29=1.7)  (29/30=0.6) ///
				    (30/100=0), gen(share_senior_imu)	
				  
* recode infant mortality
recode inf_mort_19  (0/8=26.0)   (8/9=25.6)   (9/10=24.8)   (10/11=24.0) ///
				    (11/12=23.2) (12/13=22.4) (13/14=21.5)  (14/15=20.5) ///
				    (15/16=19.5) (16/17=18.5) (17/18=17.5)  (18/19=16.4) ///
				    (19/20=15.3) (20/21=14.2) (21/22=13.1)  (22/23=11.9) ///
				    (23/24=10.8) (24/25=9.6)  (25/26=8.5)   (26/27=7.3) ///
				    (27/28=6.1)  (28/29=5.4)  (29/30=5.0)   (30/31=4.7) ///
					(31/32=4.3)  (32/33=4.0)  (33/34=3.6)   (34/35=3.3) ///
					(35/36=3.0)  (36/37=2.6)  (37/39=2.0)   (39/41=1.4) ///
					(41/43=0.8)  (43/45=0.2)  (45/100=0), gen(inf_mort_imu)	

gen imu_prelim=poor_share_imu+share_senior_imu+inf_mort_imu
gen imu_estimate=-5.4+1.1368*imu_prelim
tempfile temp
save `temp'

* merge in IMU data
use /Users/Kaveh/GitHub/mua/data/derived/mua_base, clear
keep if desig_level=="cty" & year==2007
drop if imu>62.0 // remove governor's exceptions
tempfile temp2
save `temp2'
use `temp', clear
merge 1:1 state county using `temp2'
drop if _merge==2
gen mua = (_merge==3)
drop _merge
recode imu_estimate (22/26=26)   (26/30=30)   (30/34=34)   (34/38=38) ///
					(38/42=42)   (42/46=46)   (46/50=50)   (50/54=54) ///
				    (54/58=58)   (58/62=62)   (62/66=66)   (66/70=70) ///
				    (70/74=74)   (74/78=78)   (78/82=82)   (82/86=86) ///
				    (86/90=90)   (90/94=94)   (94/98=98)  (98/102=102) ///
					, gen(imu_bins)	
collapse (mean) mua, by(imu_bins)
replace mua = 100*mua

twoway scatter mua imu_bins, ///
ytitle("probability of being assigned MUA status") ///
xtitle("IMU estimate bins (54-58, 58-62, 62-64, 64-68, etc)")
				  
