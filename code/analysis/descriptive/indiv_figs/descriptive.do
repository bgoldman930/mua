/***
Purpose: Descriptive statistics for the MUA project
Created: Benny 
***/

global root "$git/mua"

*-------------------------------------------------------------------------------
* Merge county level MUA file to Chetty data
*-------------------------------------------------------------------------------

use "${root}/data/derived/mua_base", clear

*Keep only places designated as counties after 2000
keep if year~=1978 & desig_level=="cty"

*Make a 5 digit county code for link
tostring state, replace format(%02.0f) 
tostring county, replace format(%03.0f) 
g cty=state+county
destring cty, replace
order cty

*Clean before merge
keep cty year imu poor_share share_senior inf_mort rural
rename * hrsa_*
rename (hrsa_cty hrsa_year) (cty year)

tempfile mua
save `mua'

*Use the county level life expectancy estimates
use "${root}/data/raw/health_ineq_online_table_11", clear

*Make a pooled LE variable
egen count=rowtotal(count_*)
forvalues i=1/4 {
	foreach g in M F {
		g esti_`g'_`i'=(count_q`i'_`g'/count)*le_raceadj_q`i'_`g'
	}
}
egen le=rowtotal(esti_*)
drop esti*

*Make a by gender LE variable
foreach g in M F {
	egen count_`g'=rowtotal(count_q*_`g')
	forvalues i=1/4 {
		g esti_`i'=(count_q`i'_`g'/count_`g')*le_raceadj_q`i'_`g'
	}
	egen le_`g'=rowtotal(esti_*)
	drop esti_*
}

*Make an in income LE variable
forvalues i=1/4 {
	egen count_q`i'=rowtotal(count_q`i'_*)
	foreach g in M F {
		g esti_`g'=(count_q`i'_`g'/count_q`i')*le_raceadj_q`i'_`g'
	}
	egen le_q`i'=rowtotal(esti_*)
	drop esti_*
}

order cty county_name cz_name statename count count_* le le_M le_F le_q* le_raceadj_*
keep cty county_name cz_name statename count count_* le le_M le_F le_q* le_raceadj_*

*Merge on the covarites
merge 1:1 cty using "${root}/data/raw/health_ineq_online_table_12", keep(3) nogen

*Merge on the MUA data
*We only get a match on 1/3 of places
merge 1:1 cty using `mua', nogen keep(1 3)
g mua=~mi(year)

	
*Foreign born and fraction of rich folks are highly predictive of Q1 LE
*But measures like poverty share, unemployment, IMU, are not

*-------------------------------------------------------------------------------
* Analysis
*-------------------------------------------------------------------------------

binscatter le_q1 le_q4 hrsa_imu if hrsa_imu~=0 [w=count_q1], ///
	xline(62, lcolor(gs10) lpattern(dash)) ///
	xtitle("IMU Score") ytitle("Life Expectancy") ///
	legend(order(1 "1st Quartile" 2 "4th Quartile")) ///
	title(" ")
graph export "${root}/results/figures/bin_le_imu.pdf", replace
