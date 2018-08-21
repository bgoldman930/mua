/***
• Run simple (but maybe biased) MUA regressoins
***/

*------------------------------------------------------------------------------
* Take the mortality rates wide
*------------------------------------------------------------------------------

use "${root}/data/covariates/county_mort.dta", clear

rename ageadjustedrate mort_rate
keep state county year mort_rate
reshape wide mort_rate, i(state county) j(year)
tempfile mort
save `mort'

*------------------------------------------------------------------------------
* Build the IMU score
*------------------------------------------------------------------------------

use "${root}/data/derived/mua_base.dta", clear

*Generate a dummy for being a 1978 MUA 
g mua_1978=mua==1 & year<=1978

*Cut to a sample of places with non-missing covariates
drop if mi(poor_share1970) | mi(inf_mort1966_1970) | mi(docspc1970) | mi(share_senior1970)

*Estimate the IMU score
buildimu, pov(poor_share1970) inf(inf_mort1966_1970) docs(docspc1970) old(share_senior1970) hat(imu_hat_1970)

*Merge on the mortality rates
merge 1:1 state county using `mort', assert(2 3) keep(3) nogen
rename year desig_year

*------------------------------------------------------------------------------
* Simple regressions
*------------------------------------------------------------------------------

*For now, do not worry about places that got designated after 1978. There are very few
*	designations from 1979-1994, so this can be dealth with later

*Start with mortality as the outcome variable but try to understand noise
corr mort_rate1985 mort_rate1984 mort_rate1983 mort_rate1982 mort_rate1981
corr mort_rate1985 mort_rate1984 mort_rate1983 mort_rate1982 mort_rate1981 [w=pop1980]

*The year-on-year correlation is pretty low without population weights
*Let's use a three year average - seems to boost the correlation by about 20%
*This won't attenuate the below result but it should give us more power
egen mort_rate1981_1983=rowmean(mort_rate1983 mort_rate1982 mort_rate1981)
egen mort_rate1975_1977=rowmean(mort_rate1975 mort_rate1976 mort_rate1977)
corr mort_rate1981_1983 mort_rate1985 mort_rate1984 

*Do MUAs have higher mortality rates?
*Note the ~30% increase in the t-stat when we go to the 3 year average mortality rates
*	Yes, clearly
reg mort_rate1983 mua_1978
reg mort_rate1981_1983 mua_1978

*What about conditional on IMU score and its' inputs?
*Start by documenting the relationship between mortality and IMU score before the policy
binscatter mort_rate1975_1977 imu_hat_1970, n(30) linetype(none) by(mua_1978)

*Try looking at this post policy
*XX Deal with the outlier here
binscatter mort_rate1975_1977 imu_hat_1970, n(30) linetype(none) by(mua_1978)

*Now try the regression controlling for the various components of the IMU score
*We are asking if places who have same IMU score but one got designated and one did not
*	have different mortality rates

*Run these with population weights and without population weights
g noweight=1
foreach w in pop1970 noweight {

	*Start with the poverty rate and then proceed to others
	*Woah - coefficient goes from ~60 to ~10 once you control for the poverty rate
	*What is amazing is that the other vars do not do anything to the MUA coefficient by itself
	reg mort_rate1981_1983 mua_1978 [w=`w']
	outreg2 using "${root}/results/tables/simple_regs_`w'", replace excel

	*Try with the IMU score itself
	reg mort_rate1981_1983 mua_1978 imu_hat_1970 [w=`w']
	outreg2 using "${root}/results/tables/simple_regs_`w'", excel

	*Try with the pre-period mortality rates
	*This regression suggests that we are missing something in our IMU scores
	*We want the coefficient to be 0 here because if two places have the same IMU score, but
	*	one is an MUA and the other is not and the MUA has higher mort rates, HRSA knows 
	*	something we do not=our score is off
	*That said, the coefficient gets close to 0 once you do this with population weights
	reg mort_rate1975_1977 mua_1978 imu_hat_1970 [w=`w']
	outreg2 using "${root}/results/tables/simple_regs_`w'", excel

	reg mort_rate1981_1983 mua_1978 poor_share1970 [w=`w']
	outreg2 using "${root}/results/tables/simple_regs_`w'", excel

	*This one only kills the MUA coefficient when you put in weights otherwise the inf_mort is noise
	reg mort_rate1981_1983 mua_1978 cdc_inf_mort1973_1977  [w=`w']
	outreg2 using "${root}/results/tables/simple_regs_`w'", excel

	reg mort_rate1981_1983 mua_1978 share_senior1970 [w=`w']
	outreg2 using "${root}/results/tables/simple_regs_`w'", excel

	reg mort_rate1981_1983 mua_1978 docspc1970 [w=`w']
	outreg2 using "${root}/results/tables/simple_regs_`w'", excel

	reg mort_rate1981_1983 mua_1978 poor_share1970 cdc_inf_mort1973_1977 share_senior1970 docspc1970 [w=`w']
	outreg2 using "${root}/results/tables/simple_regs_`w'", excel
}

*------------------------------------------------------------------------------
* Regressions using the difference in mortality rates
*------------------------------------------------------------------------------

*Note that there is a graphical version of these regerssions where you show how mortality
*	evolves for MUAs vs. non-MUAs but control for the confounders
*XX There are a few large outliers here need to be careful
g mort_dif=mort_rate1981_1983-mort_rate1975_1977
g mort_pct_dif=(mort_rate1981_1983-mort_rate1975_1977)/mort_rate1975_1977
su mort_dif, d
drop if mort_dif<`r(p1)' | mort_dif>`r(p99)'

*Richer places saw larger drops in mortality rates
*But this result is much weaker in percentage differences
reg mort_dif poor_share1980
reg mort_pct_dif poor_share1980

*Try the naiive regression where you compare changes in mort rates for MUAs vs. non-MUAs
*There is an impact in levels but not in percentage differences
reg mort_dif mua_1978
outreg2 using "${root}/results/tables/simple_dif_regs", replace excel

reg mort_pct_dif mua_1978

*Try adding in controls
*Motivation is that MUAs and non-MUAs might have a different mortality rate change for reasons
*	other than MUA status (like poverty rate)
*Looks like 0 impact of policy without the population weights
*	 but it is unclear what noisy quantity would motivate the weights
reg mort_dif mua_1978 poor_share1970 
outreg2 using "${root}/results/tables/simple_dif_regs", excel 

reg mort_pct_dif mua_1978 poor_share1970
reg mort_dif mua_1978 poor_share1970 [w=pop1970]
outreg2 using "${root}/results/tables/simple_dif_regs", excel addtext("Weights, Y")

reg mort_pct_dif mua_1978 poor_share1970 [w=pop1970]

*Try including other controls
*These all make it look like the policy had a literal 0 effect
reg mort_dif mua_1978 imu_hat_1970 
outreg2 using "${root}/results/tables/simple_dif_regs", excel 

reg mort_dif mua_1978 imu_hat_1970 [w=pop1970]
outreg2 using "${root}/results/tables/simple_dif_regs", excel addtext("Weights, Y")

reg mort_pct_dif mua_1978 poor_share1970 cdc_inf_mort1973_1977 [w=pop1980]
reg mort_pct_dif mua_1978 poor_share1970 cdc_inf_mort1973_1977 share_senior1970 docspc1970 [w=pop1980]


*Do this as a binscatter
binscatter mort_dif imu_hat_1970, by(mua_1978)

*------------------------------------------------------------------------------
* Try a simple time series
*------------------------------------------------------------------------------

*Limit to variables needed for the plot
keep state county mua desig_year mua_1978 imu_hat_1970 poor_share1980 poor_share1970 mort_rate*
drop mort_rate1981_1983 mort_rate1975_1977

*Reshape back long
reshape long mort_rate, i(state county mua desig_year poor_share1980 poor_share1970 mua_1978 imu_hat_1970) j(year)

*Make a naiive pot of MUAs vs. all other counties
binscatter mort_rate year, discrete rd(1978.5) by(mua_1978)

*Be a bit more restrictive, do it for only poor places
binscatter mort_rate year if poor_share>.14, discrete rd(1978.5) by(mua_1978)

*Did "better" places get healthier over this time period
*Weird to condition on 1968 mortality rates because of mean reversion - instead use poverty rate
g poor=poor_share1970>.176 if ~mi(poor_share1970)
binscatter mort_rate year if year>=1970, discrete by(poor) reportreg
