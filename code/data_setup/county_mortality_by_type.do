/***
Purpose: Build a panel of county level mortality rates by death type
***/

*---------------------------------------------------------------------
*Append the raw data
*---------------------------------------------------------------------

*Convert to .dta files
quietly forvalues i=1968/1998 {	
	noi di "Exporting `i'"
	import delimited "${root}/data/raw/mortality_by_type/Compressed Mortality `i'.txt", clear
	
	*Convert deaths variable to numeric in later years
	if `i'>=1979 {
		destring deaths population cruderatestandarderror ageadjustedratestandarderror, replace force
	}
	
	tempfile `i'
	save ``i''
}

*Append
clear
quietly forvalues i=1968/1998 {
	noi di "Appending `i'"
	append using ``i''
}

*---------------------------------------------------------------------
*Clean the by year data
*---------------------------------------------------------------------

*Make clean county and state variables
rename county countyname
tostring countycode, replace format(%05.0f) 
g state=substr(countycode, 1, 2)
g county=substr(countycode, 3, 5)
destring state county, replace

*Drop pooled total rows and the notes rows
drop if mi(year)
drop notes

*Get rid of the text strings in the rate variables
foreach v in cruderate ageadjustedrate {
	split `v', parse(" (")
	drop `v'
	destring `v'*, replace
	rename `v'1 `v'
	replace `v'=`v'2 if mi(`v')
	drop `v'2
	destring `v', replace force
}

*---------------------------------------------------------------------
*Reconcile death codes across years
*---------------------------------------------------------------------

rename icdchaptercode icd_code
g mort_type=.
replace mort_type=1 if icd_code=="E800-E999" 
replace mort_type=2 if icd_code=="760-778" | icd_code=="760-779"
replace mort_type=3 if icd_code=="630-678" | icd_code=="630-676"
replace mort_type=4 if icd_code=="740-759"
replace mort_type=5 if icd_code=="280-289"
replace mort_type=6 if icd_code=="390-458" | icd_code=="390-459"
replace mort_type=7 if icd_code=="520-579" | icd_code=="520-577"
replace mort_type=8 if icd_code=="580-629" 
replace mort_type=9 if icd_code=="710-739" | icd_code=="710-738"
replace mort_type=10 if icd_code=="320-389" 
replace mort_type=11 if icd_code=="460-519" 
replace mort_type=12 if icd_code=="680-709"
replace mort_type=13 if icd_code=="240-279"
replace mort_type=14 if icd_code=="000-136" | icd_code=="001-139"
replace mort_type=15 if icd_code=="290-319" | icd_code=="290-315"
replace mort_type=16 if icd_code=="140-239"
replace mort_type=17 if icd_code=="780-799" | icd_code=="780-796"
assert ~mi(mort_type)


label define death ///
	1 "Accidents" ///
	2 "Perinatal mortality" ///
	3 "Pregnancy" ///
	4 "Congenital anomalies" ///
	5 "Blood" ///
	6 "Circulatory" ///
	7 "Digestive" ///
	8 "Genitourinary" ///
	9 "Connective tissue" ///
	10 "Nervous system" ///
	11 "Respiratory" ///
	12 "Skin" ///
	13 "Metabolic" ///
	14 "Infectious disease" ///
	15 "Mental" ///
	16 "Neoplasms" ///
	17 "Ill-defined"
label values mort_type death

*Check to make sure everything has been properly defined
su mort_type
forvalues i=1/`r(max)' {
	tab mort_type if mort_type==`i'
	tab icdchapter if mort_type==`i'
	di _newline(5)
}

*---------------------------------------------------------------------
*Clean the by year data
*---------------------------------------------------------------------

*Clean
keep state county year mort_type population deaths cruderate cruderatestandarderror ageadjustedrate ageadjustedratestandarderror
order state county year mort_type population deaths cruderate cruderatestandarderror ageadjustedrate ageadjustedratestandarderror
sort state county year mort_type

*Drop the 0 and suppressed rows
drop if population==0 & deaths==0 & cruderate==0 & ageadjustedrate==0
drop if mi(deaths) & mi(cruderate) & mi(ageadjustedrate)

*Output
compress
save "${root}/data/covariates/county_mort_by_type.dta", replace

*---------------------------------------------------------------------
*Patterns with missing data
*---------------------------------------------------------------------

use "${root}/data/covariates/county_mort_by_type.dta", clear

decode mort_type, gen(mort_string)
levelsof mort_string, local(death_types)
quietly foreach i of local death_types {
	
	*Build the plot
	binscatter ageadjustedrate year, ///
		discrete rd(1978.5 1988.5) linetype(none) ///
		lcolor(plb1) mcolor(plb1) ///
		ytitle("Age Adjusted Mortality Rate") xtitle("Year") ///
		title("`i' Mortality Rates by Year")
	graph export "${root}/results/figures/`i'_trend.pdf", replace
		
}

*Try limiting to counties with non-missing data
levelsof mort_string, local(death_types)
quietly foreach i of local death_types {
	
	preserve
	keep if mort_string=="`i'"
	
	*Drop places with missing data in any year in the window
	bysort state county: g year_in=_N
	keep if year_in==31
	
	*Build the plot
	binscatter ageadjustedrate year, ///
		discrete rd(1978.5 1988.5) linetype(none) ///
		lcolor(plb1) mcolor(plb1) ///
		ytitle("Age Adjusted Mortality Rate") xtitle("Year") ///
		title("`i' Mortality Rates by Year")
	graph export "${root}/results/figures/`i'_trend_same_samp.pdf", replace
	
	restore
	
}

*Counts of non-missing by year
collapse (count) non_miss=ageadjustedrate,  by(mort_type mort_string year)
quietly foreach i of local death_types {
	
	*Build the plot
	twoway ///
		scatter non_miss year if mort_string=="`i'", mcolor(reddish) ///
			ytitle("Number of Counties") xtitle("Year") ///
			title("Count of Non-Missing Counties by Year") ///
			legend(off)
	graph export "${root}/results/figures/`i'_count_trend.pdf", replace
		
}
