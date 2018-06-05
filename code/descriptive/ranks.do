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

*Bar graph for doc_dens vs. low life expectancy doctor density

*Limit to counties with non-missing LE data
keep if ~mi(le_q1)

sort docs_pers
graph hbar (asis) docs_pers if _n<=10, ///
	over(name, sort(docs_pers) descending) ///
	bar(1, fcolor(black%75) lcolor(black) lwidth(*1.25)) ///
	ylabel(0(.1).5, gmax) ///
	subtitle("All Counties") ///
	title(" ") ///
	name(g1, replace)
	
su le_q1 [w=pop_2015], d
keep if le_q1<`r(p25)'
sort docs_pers
graph hbar (asis) docs_pers if _n<=10, ///
	over(name, sort(docs_pers) descending) ///
	bar(1, fcolor(dkorange%75) lcolor(dkorange) lwidth(*1.25)) ///
	ylabel(0(.1).5, gmax) ///
	subtitle("Low Life Expectancy") ///
	title(" ") ///
	name(g2, replace)
	
graph combine g1 g2, xcommon ///
	title("Doctor Density County Rankings") 
graph export "${root}/results/figures/rank_docs_all_le.pdf", replace
