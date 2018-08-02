/*
This file makes a diff-in-diff graph using all counties in 1978
It does so by merging together all covariates needed to predict the imu score
Then it predicts the imu score
And finally it makes the graph
*/

/********************************
STEP 1: MERGE TOGETHER COVARIATES
*********************************/

* DOCTOR COUNTS

* load data
use 	${root}/data/covariates/ahrf_covariates.dta, clear

* generate docs per capita 
gen 	docspc1980 = 1000*total_mds_1980/pop_1980
gen 	docspc1990 = 1000*total_mds_1990/pop_1990

* make numeric county id
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop 	st cty state county2
destring county, replace

* keep relevant vars
keep 	county docspc1980 docspc1990

* save as tempfile
tempfile 	docspc
save 		`docspc'


* GET INFANT MORTALITY

* load data
use 	${root}/data/covariates/county_infmort.dta, clear

* keep one year of data
keep if year==1980

* make numeric county id
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop 	st cty state county2
destring county, replace

* keep relevant vars
* XX use 1978 value here?
keep 	county inf_mort_1968_1978

* save as tempfile
tempfile 	infmort
save 		`infmort'

* GET POVERTY AND ELDERLY

use 	/Users/Kaveh/Desktop/poverty_old_1980, clear
rename 	share_old share_seniors

/*
* load data
use 	${root}/data/covariates/tract_covariates.dta, clear

* keep closest year
* XX 1980 covariates suck...
keep 	if year==1990

* collapse data
collapse 	(mean) poor_share share_senior [w=pop], by(state county year)

* make numeric county id
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop 	st cty state county2
destring county, replace

* keep relevant vars
keep 	county poor_share share_seniors
*/

* save as tempfile
tempfile 	poor_old
save 		`poor_old'


* GET DESIGNATION DATA

* load data
use 	${root}/data/derived/mua_base, clear

* keep relevant variables
keep 	state county tract year imu desig_level

* keep only muas designated at tract or cty level
keep 	if year==1978

* make numeric county id
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop 	st cty state county2
destring county, replace

* keep one row per county (in case of tracts)
bys 	county: gen count=_n
keep 	if count==1
drop 	count

* keep relevant vars
keep 	county imu desig_level 

* save
tempfile 	desig
save 		`desig'


* MERGE ALL TOGETHER
use 	`docspc', clear
merge 	1:1 county using `infmort'
keep 	if _merge==3
drop 	_merge
merge 	1:1 county using `poor_old'
keep 	if _merge==3
drop 	_merge
merge 	1:1 county using `desig'
drop 	if _merge==2
drop 	_merge


/********************************
STEP 2: PREDICT IMU FOR ALL COUNTIES
*********************************/

* keep only rows with all covariates
keep 	if docspc1980!=. & inf_mort!=. & poor_share!=. & share_senior!=.

* drop places designated at tract level
drop	if desig_level=="tract" | desig_level=="mcd"

* scale variables
replace 	poor_share=poor_share*100
replace 	share_senior=share_senior*100
replace 	inf_mor=inf_mor*1000
replace 	docspc1980=0.61*docspc1980 /// primary care

* recode poor_share
recode 	poor_share (0/2=24.6)   (2/4=23.7)   (4/6=22.8)   (6/8=21.9) ///
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
recode inf_mor	    (0/8=26.0)   (8/9=25.6)   (9/10=24.8)   (10/11=24.0) ///
				    (11/12=23.2) (12/13=22.4) (13/14=21.5)  (14/15=20.5) ///
				    (15/16=19.5) (16/17=18.5) (17/18=17.5)  (18/19=16.4) ///
				    (19/20=15.3) (20/21=14.2) (21/22=13.1)  (22/23=11.9) ///
				    (23/24=10.8) (24/25=9.6)  (25/26=8.5)   (26/27=7.3) ///
				    (27/28=6.1)  (28/29=5.4)  (29/30=5.0)   (30/31=4.7) ///
					(31/32=4.3)  (32/33=4.0)  (33/34=3.6)   (34/35=3.3) ///
					(35/36=3.0)  (36/37=2.6)  (37/39=2.0)   (39/41=1.4) ///
					(41/43=0.8)  (43/45=0.2)  (45/100=0), gen(inf_mort_imu)	
	

* recode doctor density
recode docspc1980		(0/0.05=0)       (0.05/0.1=0.5)  (0.1/0.15=1.5)   (.15/.2=2.8) ///
				    (.2/.25=4.1)     (.25/.3=5.7)    (.3/.35=7.3)     (.35/.4=9.0) ///
				    (.4/.45=10.7)    (.45/.5=12.6)   (.5/.55=14.8)    (.55/.6=16.9) ///
				    (.6/.65=19.1)    (.65/.7=20.7)   (.7/.75=21.9)    (.75/.8=23.1) ///
				    (.8/.85=24.3)    (.85/.9=25.3)   (.9/.95=25.9)    (.95/1.0=26.6) ///
				    (1.0/1.05=27.2)  (1.05/1.1=27.7) (1.1/1.15=28.0)  (1.15/1.2=28.3) ///
				    (1.2/1.25=28.6)  (1.25/100=28.7), gen(doc_dens_imu)	
					
* create predicted imu score				
gen 	predicted_imu=poor_share_imu + share_senior_imu + inf_mort_imu + doc_dens_imu

* make histogram
hist 	predicted_imu

/********************************
STEP 3: MAKE DD GRAPH
*********************************/

* PREP

* create designation variable
gen 	designated = (desig_level!="")

* keep relevant variables
keep 	county predicted_imu docspc1980 docspc1990 designated 

* reshape 
reshape long docspc, i(county) j(year)

* create treatment and control groups
gen 	tx = .
replace tx = 1 if (designated==1 & predicted_imu>60 & predicted_imu<62)
replace tx = 0 if (designated==0 & predicted_imu<64 & predicted_imu>62)

* collapse
collapse (mean) docspc (rawsum) county, by(year tx)

* DIFF-IN-DIFF

* make diff-in-diff graph
twoway ///
(connected  docspc year if tx==0) ///
(connected  docspc year if tx==1), ///
legend(order(1 "control" 2 "treatment"))
