/***
• Use the base file to build the first stage graph and define treatment for d n' df
***/

*------------------------------------------------------------------------------
* Build first stage graph
*------------------------------------------------------------------------------

use "${root}/data/derived/mua_base.dta", clear

*Drop the non-county mua and the governor exceptions
*XX is this the correct sampling restriction here? Could imagine wanting to include these in numerator or denom
drop if  desig_level=="tract" | desig_level=="mcd" | governor_exception==1
g mua_1978=mua==1 & year<=1978

*Document variance in infant mortality rates by population
egen inf_mort_sd=rowsd(inf_mort1966 inf_mort1967 inf_mort1968 inf_mort1969 inf_mort1970)
binscatter inf_mort_sd pop1970

*Cut to a sample of places with non-missing covariates
drop if mi(poor_share1970) | mi(inf_mort1966_1970) | mi(docspc1970) | mi(share_senior1970)
forvalues i=1968/1973 {
	drop if mi(cdc_inf_mort`i'_`=`i'+4')
}

*Try the first stage graph
buildimu, pov(poor_share1970) inf(inf_mort1966_1970) docs(docspc1970) old(share_senior1970) hat(imu_hat_1970)
binscatter mua_1978 imu_hat_1970 [w=pop1970], ///
	n(25) linetype(none) rd(62) lcolor(plb1) mcolor(plb1) ///
	xtitle("Predicted IMU Score") ytitle("Probability of 1978 MUA Assignment") ///
	title("MUA Designation vs. Predicted IMU SCore") 
graph export "${root}/results/figures/rd_stage1.pdf", replace

*Fraction correct?
g mua_hat=imu_hat_1970<=62 if ~mi(imu_hat_1970)
g correct=mua_hat==mua_1978 if ~mi(mua_hat)
su correct
di "`=round(`r(mean)'*100, .1)'% correct"

/*Iteratively choose the infant mortality rates
quietly forvalues i=1968/1974 {
*quietly foreach i in 1971 {
	replace inf_mort1966_1970=cdc_inf_mort`i'_`=`i'+4' if correct==0
	drop correct mua_hat imu_hat_1970
	buildimu, pov(poor_share1970) inf(inf_mort1966_1970) docs(docspc1970) old(share_senior1970) hat(imu_hat_1970)
	binscatter mua_1978 imu_hat_1970 [w=pop1970], linetype(qfit) rd(62) 
	g mua_hat=imu_hat_1970<=62 if ~mi(imu_hat_1970)
	g correct=mua_hat==mua_1978 if ~mi(mua_hat)
	su correct
	noi di "`=round(`r(mean)'*100, .1)'% correct"
}*/

*Assign a treatment and control for the dif n' dif
g treatment=1 if imu_hat_1970<=62 & imu_hat>=55 & mua_1978==1
replace treatment=0 if imu_hat_1970<=62 & imu_hat>=55 & mua_1978==0

keep state county imu_hat_1970 treatment
tempfile treat
save `treat'

*------------------------------------------------------------------------------
* Try a Dif n' Dif
*------------------------------------------------------------------------------

use "${root}/data/covariates/county_mort.dta", clear

*Merge on treatment
merge m:1 state county using `treat', keep(3) nogen

*Try the dif n' dif
binscatter ageadjustedrate year, ///
	discrete by(treatment) rd(1978) linetype(connect) ///
	lcolor(plb1 plg1) mcolor(plb1 plg1) ///
	ytitle("Age Adjusted Mortality Rate") xtitle("Year") ///
	title("Mortality Rates by Year and MUA Treatment Status") legend(order(1 "Control" 2 "Treatment")) 
graph export "${root}/results/figures/dif_n_dif.pdf", replace



/***
Next steps:

1. Try the RD with mortality
2. Try the dif n' dif with mortality
3. Figure out the characteristics of the places that we are misclassifying (pop density, location, classified later, etc)
4. Try to get the doctor data (get in touch with AMA masterfile people)
5. Reach out to Brandon with questions
6. Plot an F for probability break is at IMU XX by IMU score and see if 62 pops
