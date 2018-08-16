/***
• Use the base file to build the first stage graph and define treatment for d n' df
***/

*------------------------------------------------------------------------------
* Build first stage graph
*------------------------------------------------------------------------------

use "${root}/data/derived/mua_base.dta", clear

*Generate a dummy for being a 1978 MUA 
g mua_1978=mua==1 & year<=1978

*Document variance in infant mortality rates by population
*Less populus places have more variance—-harder to get the correct IMU without the exact data source
egen inf_mort_sd=rowsd(inf_mort1966 inf_mort1967 inf_mort1968 inf_mort1969 inf_mort1970)
binscatter inf_mort_sd pop1970, linetype(none)

*Cut to a sample of places with non-missing covariates
drop if mi(poor_share1970) | mi(inf_mort1966_1970) | mi(docspc1970) | mi(share_senior1970)

*Estimate the IMU score
buildimu, pov(poor_share1970) inf(inf_mort1966_1970) docs(docspc1970) old(share_senior1970) hat(imu_hat_1970)

*Fraction correct?
g mua_hat=imu_hat_1970<=62 if ~mi(imu_hat_1970)
g correct=mua_hat==mua_1978 if ~mi(mua_hat)
su correct
di "`=round(`r(mean)'*100, .1)'% correct"

*Make a map by prediction type
g predict=1 if correct==1 & imu_hat_1970<=62
replace predict=2 if correct==1 & imu_hat_1970>62
replace predict=3 if correct==0 & imu_hat_1970<=62
replace predict=4 if correct==0 & imu_hat_1970>62
tostring state, gen(st) format(%02.0f)
tostring county, gen(cty) format(%03.0f)
g tmp=st+cty
drop state county
rename tmp county
destring county, replace


*Generate a varible that contains fraction of eligible MUAs designated at the state level
*Use a cutoff of 55 instead of 62 because of measurement error
g tmp=mua_1978 if imu_hat_1970<=55
egen state_mua_eligible_mean=mean(tmp), by(state)
drop tmp

*Try the first stage graph
binscatter mua_1978 imu_hat_1970 /*[w=pop1970]*/, ///
	n(35) linetype(none) rd(62) lcolor(plb1) mcolor(plb1) ///
	xlabel(20(20)100) ylabel(0(.2)1) xmtick(##2) ymtick(##2) ///
	xtitle("Predicted IMU Score") ytitle("Probability of 1978 MUA Assignment") ///
	title("MUA Designation vs. Predicted IMU Score") 
graph export "${root}/results/figures/rd_stage1.pdf", replace

*Try the first stage graph removing states that seem to not have been part of the policy in 1978
*Force the median of the IMU score to be 62
su imu_hat_1970, d
replace imu_hat_1970=imu_hat_1970+(62-`r(p50)')
binscatter mua_1978 imu_hat_1970 if state_mua_eligible_mean>.4, ///
	n(50) linetype(none) rd(62) lcolor(reddish) mcolor(reddish) ///
	xlabel(20(20)100) ylabel(0(.2)1) xmtick(##2) ymtick(##2) ///
	xtitle("Predicted IMU Score") ytitle("Probability of 1978 MUA Assignment") ///
	title("MUA Designation vs. Predicted IMU Score") 
graph export "${root}/results/figures/rd_stage1_dropstates.pdf", replace

*Assign a treatment and control for the dif n' dif
rename year desig_year
g treatment=1 if imu_hat_1970<=62 & imu_hat>=55 & mua_1978==1
replace treatment=0 if imu_hat_1970<=62 & imu_hat>=55 & mua_1978==0 & desig_year>1985
tab treatment 

keep state county imu_hat_1970 treatment mua_1978 desig_year
tempfile treat
save `treat'


*------------------------------------------------------------------------------
* Try a Dif n' Dif
*------------------------------------------------------------------------------

use "${root}/data/covariates/county_mort.dta", clear

*Merge on treatment
merge m:1 state county using `treat', keep(3) nogen

*Scale based on event time T-1
g ageadjustedrate_scaled= .
forvalues i=0/1 {
	su ageadjustedrate if treatment==`i' & year==1977 
	replace ageadjustedrate_scaled=ageadjustedrate/`r(mean)' if treatment==`i'
}

*Try the dif n' dif
binscatter ageadjustedrate_scaled year, ///
	discrete by(treatment) rd(1978) linetype(connect) ///
	lcolor(plb1 reddish) mcolor(plb1 reddish) ///
	ytitle("Age Adjusted Mortality Rate - Relative to 1977") xtitle("Year") ///
	title("Mortality Rates by Year and MUA Treatment Status") legend(order(1 "Control" 2 "Treatment")) 
graph export "${root}/results/figures/dif_n_dif.pdf", replace

*------------------------------------------------------------------------------
* Plot Dif n' Dif estimates by bandwidth size
*------------------------------------------------------------------------------

*Keep 8 years pre and post treatment
keep if year>1970 & year<1986

*Generate the DnD vars
g post=year>1978
g did=post*treatment
reg ageadjustedrate post treatment did, r

*Validate the regression on the existing sample
binscatter ageadjustedrate year, ///
	discrete by(treatment) rd(1978) linetype(lfit) ///
	lcolor(plb1 reddish) mcolor(plb1 reddish) ///
	ytitle("Age Adjusted Mortality Rate - Relative to 1977") xtitle("Year") ///
	title("Mortality Rates by Year and MUA Treatment Status") legend(order(1 "Control" 2 "Treatment")) 
drop did treatment

*Replicate this for various bandwidth sizes
forvalues b=1/25 {
	
	*Assign a treatment and control for the dif n' dif
	g treatment=1 if imu_hat_1970<=(62+`b') & imu_hat>=(62-`b') & mua_1978==1
	replace treatment=0 if imu_hat_1970<=(62+`b') & imu_hat>=(62-`b') & mua_1978==0 ///
		& (desig_year>1986 | missing(desig_year))
	g did=post*treatment
	
	*Run the regression
	reg ageadjustedrate post treatment did, r
	
	*Build the plot
	binscatter ageadjustedrate year, ///
		discrete by(treatment) rd(1978) linetype(lfit) ///
		lcolor(plb1 reddish) mcolor(plb1 reddish) ///
		ytitle("Age Adjusted Mortality Rate") xtitle("Year") ///
		title("Mortality Rates by Year and MUA Treatment Status") legend(order(1 "Control" 2 "Treatment")) ///
		text(1350 1983 "Bandwith = `b'") ///
		text(1300 1983 "DID = `=round(_b[did], .01)'") ///
		text(1260 1983 "     (`=round(_se[did], .01)')") ///
		ylabel(800(200)1400) 
	graph export "${root}/results/figures/dif_n_dif_bwidth_`b'.pdf", replace
	
	*Populate locals with the results
	reg ageadjustedrate post treatment did, r
	local coef`b'=_b[did]
	local se`b'=_se[did]
	
	drop treatment did

}

*Plot the estimates
clear
set obs 30
g b=.
g did=. 
g se=.
forvalues b=1/25 {
	replace b=`b' in `b'
	replace did=`coef`b'' in `b'
	replace se=`se`b'' in `b'
}

g lo=did-1.96*se
g hi=did+1.96*se

*Drop the noisy estimate at 1
drop if b==1
twoway ///
	scatter did b, mcolor(black) || ///
	rcap hi lo b, lcolor(black) ///
	xtitle("IMU Treatment Bandwidth") ///
	ytitle("Difference in Differences Estimate") ///
	legend(off) ///
	title("Policy Impact by Treatment Bandwidth") 
graph export "${root}/results/figures/dif_n_dif_by_bwidth.pdf", replace

 
*------------------------------------------------------------------------------
* Plot Dif n' Dif estimates by morality type
*------------------------------------------------------------------------------
 

use "${root}/data/covariates/county_mort_by_type.dta", clear
drop if mi(ageadjustedrate)

*Merge on treatment
merge m:1 state county using `treat', keep(3) ///
	keepusing(imu_hat_1970 mua_1978 desig_year) nogen

*Keep 8 years pre and post treatment
keep if year>1970 & year<1986
			
*Run the estimate by mortality type
*Use a bandwidth of 6 from the previous analysis
g treatment=1 if imu_hat_1970<=(62+6) & imu_hat_1970>=(62-6) & mua_1978==1
replace treatment=0 if imu_hat_1970<=(62+6) & imu_hat_1970>=(62-6) & mua_1978==0 ///
	& (desig_year>1986 | missing(desig_year))
	
*Generate the DnD vars
g post=year>1978
g did=post*treatment
reg ageadjustedrate post treatment did, r

decode mort_type, gen(mort_string)
levelsof mort_string, local(death_types)
quietly foreach i of local death_types {
	
	preserve
	keep if mort_string=="`i'"
	
	*Drop places with missing data in any year in the window
	bysort state county: g year_in=_N
	keep if year_in==15
	
	*Run the regression
	reg ageadjustedrate post treatment did, r
	
	*Build the plot
	binscatter ageadjustedrate year, ///
		discrete by(treatment) rd(1978) linetype(lfit) ///
		lcolor(plb1 reddish) mcolor(plb1 reddish) ///
		ytitle("Age Adjusted Mortality Rate") xtitle("Year") ///
		title("`i' Mortality Rates by Year and MUA Treatment Status") legend(order(1 "Control" 2 "Treatment")) 
	graph export "${root}/results/figures/dif_n_dif_`i'.pdf", replace
	
	*Populate locals with the results
	reg ageadjustedrate post treatment did if mort_string=="`i'", r
	local coef`b'=_b[did]
	local se`b'=_se[did]
	
	restore
	
}
			
/***
Next steps:

1. Try the RD with mortality
2. Try the dif n' dif with mortality
3. Figure out the characteristics of the places that we are misclassifying (pop density, location, classified later, etc)
4. Try to get the doctor data (get in touch with AMA masterfile people)
5. Reach out to Brandon with questions
6. Plot an F for probability break is at IMU XX by IMU score and see if 62 pops
7. Plot dif n' dif estimate against size of bandwith for treatment and control around 62
8. Try parameterizing the DnD

Dev's birth weight data

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
