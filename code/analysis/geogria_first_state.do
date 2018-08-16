/***
• Test the updated Georgia doctor data
***/

*------------------------------------------------------------------------------
* Build first stage graph
*------------------------------------------------------------------------------

use "${root}/data/derived/mua_base.dta", clear

*Keep only Georgia counties 
keep if state==13

*Drop the non-county mua and the governor exceptions
g mua_1978=mua==1 & year<=1978

*Document variance in infant mortality rates by population
egen inf_mort_sd=rowsd(inf_mort1966 inf_mort1967 inf_mort1968 inf_mort1969 inf_mort1970)
*binscatter inf_mort_sd pop1970

*Cut to a sample of places with non-missing covariates
drop if mi(poor_share1970) | mi(inf_mort1966_1970) | mi(docspc1970) | mi(share_senior1970)

*Try the first stage graph
buildimu, pov(poor_share1970) inf(inf_mort1966_1970) docs(docspc1970) old(share_senior1970) hat(imu_hat_1970)
binscatter mua_1978 imu_hat_1970 [w=pop1970], ///
	n(35) linetype(none) rd(62) lcolor(plb1) mcolor(plb1) ///
	xtitle("Predicted IMU Score") ytitle("Probability of 1978 MUA Assignment") ///
	title("MUA Designation vs. Predicted IMU SCore") 
graph export "${root}/results/figures/rd_stage1_georgia.pdf", replace

*Fraction correct?
g mua_hat=imu_hat_1970<=62 if ~mi(imu_hat_1970)
g correct=mua_hat==mua_1978 if ~mi(mua_hat)
su correct
di "`=round(`r(mean)'*100, .1)'% correct"
drop mua_hat

*Try this in Georgia only with the updated doctor data
buildimu, pov(poor_share1970) inf(inf_mort1966_1970) docs(kaveh_docspc1975) old(share_senior1970) hat(kaveh_imu_hat_1970)
binscatter mua_1978 kaveh_imu_hat_1970 [w=pop1970], ///
	n(35) linetype(none) rd(62) lcolor(plb1) mcolor(plb1) ///
	xlabel(20(20)80) ///
	xtitle("Predicted IMU Score") ytitle("Probability of 1978 MUA Assignment") ///
	title("MUA Designation vs. Predicted IMU SCore") 
graph export "${root}/results/figures/rd_stage1_georgia_new_data.pdf", replace

*Fraction correct?
g mua_hat=kaveh_imu_hat_1970<=62 if ~mi(kaveh_imu_hat_1970)
g correct_new=mua_hat==mua_1978 if ~mi(mua_hat)
su correct_new
di "`=round(`r(mean)'*100, .1)'% correct"
