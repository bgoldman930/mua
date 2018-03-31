/***
Purpose: Rankings of places in need
***/

use "${root}/data/covariates/ahrf_covariates", clear

*Doctors per 100 low-income people
g docs_poor_pers=1000*(total_mds_2015/poor_pop_2015)

*Merge on county names
tostring state, format(%02.0f) replace
tostring county, format(%03.0f) replace
g cty=state+county
destring cty, replace
merge 1:1 cty using "${root}/data/raw/health_ineq_online_table_12", ///
	keepusing(county_name stateabbrv) nogen keep(3)
g name=county_name+", "+stateabbrv

*Keep counties with at least 3000 people and high-poverty
g poor_share_2015=poor_pop_2015/pop_2015
su poor_share_2015 [w=pop_2015], d
preserve
keep if pop_2015>3000 & poor_share_2015>`r(p50)' & total_mds_2015>0 & total_mds_2015<.

*Bar graph of top places
gsort -docs_poor_pers
graph hbar (asis) docs_poor_pers if _n<=10, ///
	over(name, sort(docs_poor_pers) descending) ///
	bar(1, fcolor(midgreen%75) lcolor(midgreen) lwidth(*1.25)) ///
	subtitle("Top 10") ///
	title(" ") ///
	name(g1, replace)
	
sort docs_poor_pers
graph hbar (asis) docs_poor_pers if _n<=10, ///
	over(name, sort(docs_poor_pers) descending) ///
	bar(1, fcolor(red%75) lcolor(red) lwidth(*1.25)) ///
	subtitle("Bottom 10") ///
	ylabel(0(.25)1, gmax) ///
	title(" ") ///
	name(g2, replace)
	
graph combine g1 g2
graph export "${root}/results/figures/rank_docs_poor.pdf", replace

*** Repeat for seniors ***
restore

g share_senior_2015=seniors_pop_2015/pop_2015
su share_senior_2015 [w=pop_2015], d
preserve
keep if pop_2015>3000 & share_senior_2015>`r(p50)' & total_mds_2015>0 & total_mds_2015<.

*Doctors per senior
g docs_sen_pers=1000*(total_mds_2015/seniors_pop_2015)

*Bar graph of top places
gsort -docs_sen_pers
graph hbar (asis) docs_sen_pers if _n<=10, ///
	over(name, sort(docs_sen_pers) descending) ///
	bar(1, fcolor(midgreen%75) lcolor(midgreen) lwidth(*1.25)) ///
	subtitle("Top 10") ///
	title(" ") ///
	name(g1, replace)
	
sort docs_sen_pers
graph hbar (asis) docs_sen_pers if _n<=10, ///
	over(name, sort(docs_sen_pers) descending) ///
	bar(1, fcolor(red%75) lcolor(red) lwidth(*1.25)) ///
	subtitle("Bottom 10") ///
	ylabel(0(.2)1, gmax) ///
	title(" ") ///
	name(g2, replace)
	
graph combine g1 g2
graph export "${root}/results/figures/rank_docs_senior.pdf", replace
