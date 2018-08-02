/*
This file makes a first stage graph using all counties in 1978
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
gen 	docspc1970 = 1000*total_mds_1970/pop_1970
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
keep 	county docspc1970 docspc1980 docspc1990 

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

use 	/Users/Kaveh/Desktop/poverty_old_1970, clear // XX Benny these are from the new covariate file you sent me, my b on not uploading etc
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
replace 	docspc1970=0.61*docspc1970 // primary care - note this is a total guess for now

* round variables
replace 	poor_share = round(poor_share, 0.1)
replace 	share_senior = round(share_senior, 0.1)
replace 	inf_mort = round(inf_mort, 0.1)
replace 	docspc1970 = round(docspc1970, 0.001)


* recode poor_share
recode 	poor_share (0.1/2=24.6)   (2.1/4=23.7)   (4.1/6=22.8)   (6.1/8=21.9) ///
				  (8.1/10=21.0)  (10.1/12=20.0) (12.1/14=18.7) (14.1/16=17.4) ///
				  (16.1/18=16.2) (18.1/20=14.9) (20.1/22=13.6) (22.1/24=12.2) ///
				  (24.1/26=10.9) (26.1/28=9.3)  (28.1/30=7.8)  (30.1/32=6.6) ///
				  (32.1/34=5.6)  (34.1/36=4.7)  (36.1/38=3.4)  (38.1/40=2.1) ///
				  (40.1/42=1.3)  (42.1/44=1.0)  (44.1/46=0.7)  (46.1/48=0.4) ///
				  (48.1/50=0.1)  (50/100=0), gen(poor_share_imu)	
replace poor_share_imu=25.1 if poor_share==0

* recode share_senior
recode share_senior (0/7=20.2)   (7.1/8=20.1)   (8.1/9=19.9)   (9.1/10=19.8) ///
				    (10.1/11=19.6) (11.1/12=19.4) (12.1/13=19.1) (13.1/14=18.9) ///
				    (14.1/15=18.7) (15.1/16=17.8) (16.1/17=16.1) (17.1/18=14.4) ///
				    (18.1/19=12.8) (19.1/20=11.1) (20.1/21=9.8)  (21.1/22=8.9) ///
				    (22.1/23=8.0)  (23.1/24=7.0)  (24.1/25=6.1)  (25.1/26=5.1) ///
				    (26.1/27=4.0)  (27.1/28=2.8)  (28.1/29=1.7)  (29.1/30=0.6) ///
				    (30/100=0), gen(share_senior_imu)	
				  
* recode infant mortality
recode inf_mor	    (0/10=26.0)   (10.1/11=25.6)   (11.1/12=24.8)   (12.1/13=24.0) ///
				    (13.1/14=23.2) (14.1/15=22.4) (15.1/16=21.5)  (16.1/17=20.5) ///
				    (17.1/18=19.5) (18.1/19=18.5) (19.1/20=17.5)  (20.1/21=16.4) ///
				    (21.1/22=15.3) (22.1/23=14.2) (23.1/24=13.1)  (24.1/25=11.9) ///
				    (25.1/26=10.8) (26.1/27=9.6)  (27.1/28=8.5)   (28.1/29=7.3) ///
				    (29.1/30=6.1)  (30.1/31=5.4)  (31.1/32=5.0)   (32.1/33=4.7) ///
					(33.1/34=4.3)  (34.1/35=4.0)  (35.1/36=3.6)   (36.1/37=3.3) ///
					(37.1/38=3.0)  (38.1/39=2.6)  (39.1/40=2.3)   (30.1/41=2.0) ///
					(41.1/42=1.8)  (42.1/43=1.6)  (43.1/44=1.4)   (44.1/45=1.2) /// 
					(45.1/46=1.0)  (46.1/47=0.8)  (47.1/48=0.6)   (48.1/49=0.3) ///
					(49.1/50=0.1)  (50/1000=0), gen(inf_mort_imu)	
	

* recode doctor density
recode docspc1970	(.001/0.05=0.5)   (.051/0.1=1.6)  (.101/0.15=2.8)   (.151/.2=4.1) ///
				    (.201/.25=5.7)     (.251/.3=7.3)    (.301/.35=9.0)     (.351/.4=10.7) ///
				    (.401/.45=12.6)    (.451/.5=14.8)   (.501/.55=16.9)    (.551/.6=19.1) ///
				    (.601/.65=20.7)    (.651/.7=21.9)   (.701/.75=23.1)    (.751/.8=24.3) ///
				    (.801/.85=25.3)    (.851/.9=25.9)   (.901/.95=26.6)    (.951/1.0=27.2) ///
				    (1.001/1.05=27.7)  (1.051/1.1=28.0) (1.101/1.15=28.3)  (1.151/1.2=28.6) ///
				    (1.2/1000=28.7), gen(doc_dens_imu)	
					
* create predicted imu score				
gen 	predicted_imu=poor_share_imu + share_senior_imu + inf_mort_imu + doc_dens_imu

* make histogram
hist 	predicted_imu

* now create bins
drop 	if predicted_imu>100
xtile 	imu_bin = predicted_imu, n(30)
*gen imu_bin = round(predicted_imu)

/*
recode predicted_imu (0/5=5)   (5/10=10)   (10/15=15)   (15/20=20) ///
				    (20/25=25) (25/30=30) (30/35=35)  (35/40=40) ///
				    (40/45=45) (45/50=50) (50/55=55)  (55/60=60) ///
				    (60/65=65) (65/70=70) (70/75=75)  (75/80=80) ///
				    (80/85=85) (85/90=90)  (90/95=95)   (95/1000=100), gen(imu_bin)	
*/
					
/********************************
STEP 3: MAKE FS+RF GRAPHS
*********************************/

* PREP

* create designation variable
gen 	designated = (desig_level!="")

* create doctor outcome variable
gen 	docs_change = (docspc1990-docspc1980)/docspc1980

* collapse
collapse (mean) designated docs_change predicted_imu (count) poor_share, by(imu_bin)

* FIRST STAGE

* make first stage graph
twoway 	scatter designated predicted_imu

* make first stage graph with smooths
twoway ///
(scatter designated predicted_imu, xline(62)) ///
(lpolyci designated predicted_imu if predicted_imu<62, fcolor(none)) ///
(lpolyci designated predicted_imu if predicted_imu>=62, fcolor(none)), xline(0)  legend(off)

* make first stage graph with smooths - zoom in on cutoff
twoway ///
(scatter designated predicted_imu if predicted_imu>40 & predicted_imu<80, xline(62)) ///
(lpolyci designated predicted_imu if predicted_imu<62 & predicted_imu>40, fcolor(none)) ///
(lpolyci designated predicted_imu if predicted_imu>=62 & predicted_imu<80, fcolor(none)), xline(0)  legend(off)

* make reduced form graph
twoway scatter docs_change predicted_imu

* make reduced form graph with smooths
twoway ///
(scatter docs_change predicted_imu, xline(62)) ///
(lpolyci docs_change predicted_imu if predicted_imu<62, fcolor(none)) ///
(lpolyci docs_change predicted_imu if predicted_imu>=62, fcolor(none)), xline(0)  legend(off)

* make reduced form graph with smooths - zoom in on cutoff
twoway ///
(scatter docs_change predicted_imu if predicted_imu>40 & predicted_imu<80, xline(62)) ///
(lpolyci docs_change predicted_imu if predicted_imu<62 & predicted_imu>40, fcolor(none)) ///
(lpolyci docs_change predicted_imu if predicted_imu>=62 & predicted_imu<80, fcolor(none)), xline(0)  legend(off)


