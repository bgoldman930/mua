/***
Purpose: Simulate MUA DGP to see if we can uncover a treatment effect
***/

clear
set scheme plotplain
set obs 3200
set seed 20

*Generate a county identifier
g cty=_n

*Distribution of the true IMU score
g imu=rnormal(62, 10)

*Generate treatment based on the IMU score (note this is actually observed)
g treat=imu<62

*Now generate the noised up (observed) imu score
g imu_noise=imu+rnormal(0, 7)

*Generate an ITT variable based of the noisy IMU
g treat_noise=imu_noise<62

*Build an outcome variable that is a function of the IMU score and the treatment
*In our data imu has a coef of 2.6 in the below reg—you get this with a slope of 5 in true IMU
*So is the mean of the mortality rates
g mort=-5*imu-30*treat+rnormal(0, 200)
su mort
replace mort=mort+(1086-`r(mean)')

*True first stage graph
binscatter treat imu, rd(62) n(50) linetype(none) title("True First Stage") 
graph export "${root}/results/figures/sim_stage1.pdf", replace

*Build the first stage graph
binscatter treat imu_noise, rd(62) n(50) linetype(none) ///
	title("First Stage with Noisy Observed IMU Score") 
graph export "${root}/results/figures/sim_noise_stage1.pdf", replace

*Graph of the true estimate
binscatter mort imu, rd(62) n(30) title("True Second Stage")
graph export "${root}/results/figures/sim_stage2.pdf", replace 
reg mort imu treat // the true policy estimate

*Graph of the biased estimate
binscatter mort imu_noise, rd(62) n(30) ///
	title("Second Stage with Noisy Observed IMU Score") 
graph export "${root}/results/figures/sim_noise_stage2.pdf", replace
reg mort imu_noise treat_noise // the biased policy estimate

*Graph the nosied up second stage treatment effect as a function of the amount of noise 
*	in the IMU score
forvalues i=1/50 {
	drop imu_noise treat_noise
	g imu_noise=imu+rnormal(0, `i')
	g treat_noise=imu_noise<62
	reg mort imu_noise treat_noise
	local te`i'=_b[treat_noise]
	local se`i'=_se[treat_noise]
	corr imu imu_noise
	local corr`i'=`r(rho)'
}
	
*Plot the estimates
clear
set obs 50
g te=.
g se=. 
g rho=.
forvalues i=1/50 {
	replace te=`te`i'' in `i'
	replace se=`se`i'' in `i'
	replace rho=`corr`i'' in `i'
}
g lo=te-1.96*se
g hi=te+1.96*se

twoway ///
	scatter te rho, mcolor(black) || ///
	rcap hi lo rho, lcolor(black) ///
	xtitle("IMU Treatment Bandwidth") ///
	ytitle("Difference in Differences Estimate") ///
	legend(off) ///
	title("Policy Impact by Treatment Bandwidth") 
graph export "${root}/results/figures/dif_n_dif_by_bwidth.pdf", replace
