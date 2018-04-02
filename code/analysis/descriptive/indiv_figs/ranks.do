/***
Purpose: Rankings of places in need
***/

use "${root}/data/covariates/ahrf_covariates", clear

*Doctors per 100 low-income people
g docs_pers=1000*(total_mds_2015/pop_2015)

*Merge on county names
tostring state, format(%02.0f) replace
tostring county, format(%03.0f) replace
g cty=state+county
destring cty, replace
merge 1:1 cty using "${root}/data/raw/health_ineq_online_table_12", ///
	keepusing(county_name stateabbrv) nogen keep(3)
g name=county_name+", "+stateabbrv

*Merge on the life expectency data
merge 1:1 cty using "${root}/data/raw/health_ineq_online_table_11", keep(3) nogen

*Make an in income LE variable
forvalues i=1/4 {
	egen count_q`i'=rowtotal(count_q`i'_*)
	foreach g in M F {
		g esti_`g'=(count_q`i'_`g'/count_q`i')*le_raceadj_q`i'_`g'
	}
	egen le_q`i'=rowtotal(esti_*)
	drop esti_*
}

*Bar graph of top places of LE for the poor
gsort -le_q1
replace le_q1=le_q1-70
graph hbar (asis) le_q1 if _n<=10, ///
	over(name, sort(le_q1) descending) ///
	bar(1, fcolor(midgreen%75) lcolor(midgreen) lwidth(*1.25)) ///
	ylabel(0 "70" 5 "75" 10 "80" 15 "85", gmax) ///
	subtitle("Top 10") ///
	title(" ") ///
	name(g1, replace)
	
sort le_q1
graph hbar (asis) le_q1 if _n<=10, ///
	over(name, sort(le_q1) descending) ///
	bar(1, fcolor(red%75) lcolor(red) lwidth(*1.25)) ///
	subtitle("Bottom 10") ///
	ylabel(0 "70" 5 "75" 10 "80" 15 "85", gmax) ///
	title(" ") ///
	name(g2, replace)
	
graph combine g1 g2
graph export "${root}/results/figures/rank_le_q1.pdf", replace

*** Repeat for bottom quartile places ***

su le_q1, d
keep if le_q1<`r(p25)'

*Bar graph of top places
gsort -docs_pers
graph hbar (asis) docs_pers if _n<=10, ///
	over(name, sort(docs_pers) descending) ///
	bar(1, fcolor(midgreen%75) lcolor(midgreen) lwidth(*1.25)) ///
	subtitle("Top 10") ///
	title(" ") ///
	name(g1, replace)
	
sort docs_pers
graph hbar (asis) docs_pers if _n<=10, ///
	over(name, sort(docs_pers) descending) ///
	bar(1, fcolor(red%75) lcolor(red) lwidth(*1.25)) ///
	subtitle("Bottom 10") ///
	ylabel(0(.2)1, gmax) ///
	title(" ") ///
	name(g2, replace)
	
graph combine g1 g2
graph export "${root}/results/figures/rank_docs_low_le.pdf", replace
