/***
• Build a map of prediction status
***/

*------------------------------------------------------------------------------
* Build first stage graph
*------------------------------------------------------------------------------

use "${root}/data/derived/mua_base.dta", clear

*Generate a dummy for being a 1978 MUA 
g mua_1978=mua==1 & year<=1978

*Cut to a sample of places with non-missing covariates
drop if mi(poor_share1970) | mi(inf_mort1966_1970) | mi(docspc1970) | mi(share_senior1970)

*Estimate the IMU score
buildimu, pov(poor_share1970) inf(inf_mort1966_1970) docs(docspc1970) old(share_senior1970) hat(imu_hat_1970)

*Fraction correct?
g mua_hat=imu_hat_1970<=62 if ~mi(imu_hat_1970)
g correct=mua_hat==mua_1978 if ~mi(mua_hat)
su correct
di "`=round(`r(mean)'*100, .1)'% correct"

*Classify prediction types
g predict=1 if correct==1 & imu_hat_1970<=62
replace predict=2 if correct==1 & imu_hat_1970>62
replace predict=3 if correct==0 & imu_hat_1970<=62
replace predict=4 if correct==0 & imu_hat_1970>62

*Make combined county variable
tostring state, gen(st) format(%02.0f)
tostring county, gen(cty) format(%03.0f)
g tmp=st+cty
drop state county
rename tmp county
destring county, replace

*Build map
maptile predict, geo(county1990) stateoutline(*.75) fcolor(Accent) ///
	twopt(legend(order(1 "No Data" 2 "True +" 3 "True -" 4 "False +" 5 "False -")) ///
	title("MUA County Level Prediction"))
graph export "${root}/results/figures/prediction_map.pdf", replace

