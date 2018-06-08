set more off

/*

This file checks how well we can predict IMU scores. (It is very incomplete at the moment.)

It does so by attempting to compute imu score & compare it to actual imu score for counties designated as muas in 2007.

The file proceeds in three steps:
1. load decennial tract-level panel of poor share and senior share, collapse to county-level, and interpolate 
2. combine two sources of infant mortality data, interpolate, and join to output of 1
3. predict imu score using data generated in 1 and 2

Note this was attempted before the covariates panel was created. so it is not done as cleanly as one might expect....

*/

* load in data
use 	${root}/data/derived/mua_base, clear

* limit to places designated at county level in 2007
keep 	if desig_level=="cty" & year==2007
keep 	state county year imu poor_share share_senior inf_mort rural 

* merge in infant mortality data
rename 	inf_mort inf_mort_mua
merge 	1:1 state county year using ${root}/data/covariates/county_infmort, keepusing(inf_mort inf_mort_1999_2016)
drop 	if _merge==2
drop 	_merge
replace inf_mort = inf_mort*1000
replace inf_mort_1999_2016 = inf_mort_1999_2016*1000
order 	inf_mort_mua inf_mort_1999 inf_mort 
merge 	1:1 state county using ${root}/data/covariates/ahrf_covariates, keepusing(inf_mort_*)
drop 	if _merge==2
drop 	_merge

* merge in poor_share data
rename poor_share poor_share_mua
merge 	1:1 state county using ${root}/data/covariates/ahrf_covariates, keepusing(poor_share_2005 pop_2005)
drop 	if _merge==2
drop	 _merge
gen 	poor_share = poor_share_2005/pop_2005
order 	poor_share_mua poor_share 
replace poor_share=100*poor_share

* merge in senior_share data
rename 	share_senior senior_share_mua
merge 	1:1 state county using ${root}/data/covariates/ahrf_covariates, keepusing(seniors_pop_2005 pop_2005 pop_2007)
drop 	if _merge==2
drop 	_merge
gen 	share_senior = seniors_pop_2005/pop_2005
replace share_senior = share_senior*100
order 	senior_share_mua share_senior

* merge in doctor data
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop 	st cty
merge 	1:1 county year using /Users/Kaveh/Dropbox/mua/raw/ama/ama_county_data
drop 	if _merge==2
drop 	_merge
gen 	doc_dens = 1000*(totpc/pop_2007)

* keep relevant variables 
keep 	senior_share_mua share_senior poor_share_mua poor_share inf_mort_mua inf_mort_1996_2000 state county2 year imu rural county totpc doc_dens

* now recode covariates to align with stupid imu tables

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
					
* recode doctor density
recode doc_dens		(0/0.05=0)       (0.05/0.1=0.5)  (0.1/0.15=1.5)   (.15/.2=2.8) ///
				    (.2/.25=4.1)     (.25/.3=5.7)    (.3/.35=7.3)     (.35/.4=9.0) ///
				    (.4/.45=10.7)    (.45/.5=12.6)   (.5/.55=14.8)    (.55/.6=16.9) ///
				    (.6/.65=19.1)    (.65/.7=20.7)   (.7/.75=21.9)    (.75/.8=23.1) ///
				    (.8/.85=24.3)    (.85/.9=25.3)   (.9/.95=25.9)    (.95/1.0=26.6) ///
				    (1.0/1.05=27.2)  (1.05/1.1=27.7) (1.1/1.15=28.0)  (1.15/1.2=28.3) ///
				    (1.2/1.25=28.6)  (1.25/100=28.7), gen(doc_dens_imu)	
	
* generate imu prediction
gen 	predicted_imu=poor_share_imu+share_senior_imu+inf_mort_imu

* run correlation and regression
corr imu predicted_imu 
reg imu predicted_imu

* generate rough predicted score
gen predicted_imu2 =   -5.40022 +   1.136819*predicted_imu


* NEXT STEPS: 
** repeat this for all counties after 1999
** to do this will need to interpolate to construct county-year panel with poor share, senior share, and infant mortality
** then can merge in covariates at the county-year level and compute the IMU estimates
** once we have estimates can do a few things:
*** make RD graph of doctor density
*** use estimates to define Tx and control groups (58-62 vs 62-66), then make diff-in-diff graph 
* later
** make RD graph of preventable hospitalizations
