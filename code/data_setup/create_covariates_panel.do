set more off

/*

This file creates a county-level covariates panel, 1990-2010, which includes infant mortality, poor share, senior share, and imu score.

Note doctor density is missing for now.

The file proceeds in three steps:
1. load decennial tract-level panel of poor share and senior share, collapse to county-level, and interpolate 
2. combine two sources of infant mortality data, interpolate, and join to output of 1
3. predict imu score using data generated in 1 and 2

*/


* STEP 1: LOAD DECENNIAL TRACT-LEVEL PANEL OF COVARIATES AND INTERPOLATE INTO ANNUAL COUNTY-LEVEL (1990-2010) PANEL

* load decennial panel
use 	${root}/data/covariates/tract_covariates, clear

* keep relevant vars and rows
keep 	state county tract year pop popdensity share_senior poor_share
drop if year==1980

* collapse to county-level 
collapse (mean) share_senior poor_share popdensity (rawsum) pop [w=pop], by(state county year)

* make numeric county id
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop 	st cty state county2
destring county, replace

* turn into annual pannel
xtset 	county year
tsfill

* turn county back into string
gen 	county2 = string(county, "%05.0f")
drop 	county
rename 	county2 county

* merge on the doctor data
merge 1:1 county year using ${root}/data/derived/ama_county_data, ///
	keepusing(tot) keep(1 3) nogen
rename tot docs

* do interpolation
order 	county year
foreach x in share_senior poor_share docs pop popdensity {
	by 		county: ipolate `x' year, gen(`x'_ip) 
}
g docs_pers_ip=docs_ip/pop_ip
drop 	share_seniors poor_share pop docs_ip docs popdensity

* save 
tempfile part1
save `part1'

* STEP 2: ADD INFANT MORTALITY DATA (FROM AHRF AND CDC) TO THE MIX 
* XX this is very rough due to the poor infant mortality data; should def be cleaned up at some point

* load ahrf data
use 	${root}/data/covariates/ahrf_covariates, clear 

* keep relevant variables
keep 	state county inf_mort_*

* rename to keep names reasonable
rename 	inf_mort_1996 inf_mort_1996
rename 	inf_mort_2001 inf_mort_2001
rename 	inf_mort_2002 inf_mort_2002
rename 	inf_mort_2003 inf_mort_2003
rename 	inf_mort_2004 inf_mort_2004
rename 	inf_mort_2005 inf_mort_2005
rename 	inf_mort_2006 inf_mort_2006
rename 	inf_mort_2007 inf_mort_2007
rename 	inf_mort_2008 inf_mort_2008
rename 	inf_mort_2009 inf_mort_2009
rename 	inf_mort_2010 inf_mort_2010

* reshape to county-year level
reshape long inf_mort_, i(state county) j(year)

* merge in cdc data
merge 	1:1 state county year using ${root}/data/covariates/county_infmort
drop 	_merge

* keep only relevant years
keep 	if year>1989

* keep only relevant vars
drop 	deaths* births* inf_mort_1968

* rescale to be consistent
replace 	inf_mort=inf_mort*1000
replace 	inf_mort_1979=inf_mort_1979*1000
replace 	inf_mort_1999=inf_mort_1999*1000
replace 	inf_mort_=inf_mort if inf_mort_==.
replace 	inf_mort_=inf_mort_1999_2016 if inf_mort_==. & year>1998
replace 	inf_mort_=(0.7*inf_mort_1999_2016+0.3*inf_mort_1979_1998) if inf_mort_==. & year<=1998 //note this is BS

* interpolate
sort 	state county year
by 		state county: ipolate inf_mort_ year, gen(inf_mort_ip) epolate
replace inf_mort_ip=0 if inf_mort_ip<0
keep 	state county year inf_mort_ip

* create county id
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop 	st cty state county2

* get rid of anything after 2010
drop 	if year>2010

* merge in file created in step 1
merge 	1:1 county year using `part1'
drop 	_merge

* housekeeping
destring county, replace
order county year
sort county year
xtset county year
tsfill

* save (over-write previous version)
save ${root}/data/derived/county_covariates_interpolated, replace
e

* STEP 3: PREDICT IMU SCORES AND ADD THEM TO PANEL
* XX note here we are not using the doctor data in the IMU score

* rescale vars to be consistent with IMU tables
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
					

* generate raw predicted IMU score by summing the components
gen 	predicted_imu_raw = poor_share_imu+share_senior_imu+inf_mort_imu

* use previous regression results to scale prediction up (recall we are missing doc dens)
* regression results come from predict_imu_scores.do - super rough
gen 	predicted_imu =  -5.40022 +   1.136819*predicted_imu_raw

* keep relevant variables
order 	county year share_senior_ip poor_share_ip inf_mort_ip predicted_imu
keep 	county year share_senior_ip poor_share_ip inf_mort_ip predicted_imu pop_ip

* convert county back into string
gen 	county2 = string(county, "%05.0f")
drop 	county
rename 	county2 county
order 	county year

* save 
save ${root}/data/derived/county_covariates_interpolated_imu, replace
