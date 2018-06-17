/***
Purpose: Benny takes a swing at predicting the IMU scores and running first stage
***/

set more off

*------------------------------------------------------------------------------
* Rough prediction of the IMU scores
*------------------------------------------------------------------------------

use "${root}/data/derived/mua_base", clear

*Create county id
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop 	st cty state county2
destring county, replace

*Distribution of IMU scores looks good without the 0's
drop if imu==0 | missing(imu)
su imu, d

*Merge on our covariates
merge m:1 county year using ${root}/data/derived/county_covariates_interpolated, keep(3) nogen

*Keep only county level designations
keep if desig_level=="cty"

*Run the regression 
*Create a dummy for pre and post 2000 to account for measurement issues
g pre_2000=year<2000
xi: reg imu i.pre_2000*inf_mort_ip i.pre_2000*share_senior_ip i.pre_2000*poor_share_ip i.pre_2000*docs_pers_ip
estimate store pred_imu_full

xi: reg imu i.pre_2000*share_senior_ip i.pre_2000*poor_share_ip
estimate store pred_imu_mini

*------------------------------------------------------------------------------
* Store a panel of all MUA counties
*------------------------------------------------------------------------------

use "${root}/data/derived/mua_base", clear

*Create county id
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop 	st cty state county2
destring county, replace

*Keep only post 1990 county designations because of covariates
keep if desig_level=="cty"
g pre_1990=year<1990
keep county pre_1990
tempfile cty_list
save `cty_list'

*------------------------------------------------------------------------------
* Merge onto covariates and build first stage
*------------------------------------------------------------------------------

use ${root}/data/derived/county_covariates_interpolated, clear

*Run regression to get the xi variables
g pre_2000=year<2000
g y=runiform()
xi: reg y i.pre_2000*inf_mort_ip i.pre_2000*share_senior_ip i.pre_2000*poor_share_ip i.pre_2000*docs_pers_ip
drop y

*Fill in predicted IMU scores
estimate restore pred_imu_mini
predict imu_hat_mini, xb
estimate restore pred_imu_full
predict imu_hat_full, xb

*Take the minimum IMU score by county and the mean of a bunch of useful vars
collapse 	(min) min_imu_mini=imu_hat_mini min_imu_full=imu_hat_full ///
			(mean) mean_imu_mini=imu_hat_mini mean_imu_full=imu_hat_full ///
				inf_mort_ip share_senior_ip poor_share_ip popdensity_ip ///
					docs_pers_ip pop_ip ///
			[w=pop_ip], by(county)
			
*Merge on the list of MUA's
merge 1:1 county using `cty_list'
g mua=_merge==3
drop _merge

*Drop the counties designated before 1990
drop if pre_1990==1
			
*Try a few first stage graphs
*Essentially no luck - the mean version looks better
*Generally, the IMU predictions are very low (most places are IMU<62 at some point)
binscatter mua mean_imu_full, n(40)
binscatter mua min_imu_full, n(40)

*Try with the simplified reg
binscatter mua mean_imu_mini, n(40)

*Try restricting to rural place
binscatter mua mean_imu_mini if popdensity_ip<500, n(40)
