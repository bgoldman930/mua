set more off 

/*
This file cleans clinic data from HRSA (emailed by Brandon in jan 2018).
*/

cd ${root}/data/raw/hrsa_clinic_data

* load annual data, collapse by zip, merge to zip-county crosswalk, collapse by county, save as tempfile
forvalues y=1996(1)2015 {
	insheet  using clinics`y'.csv, comma clear
	if	`y'==1999 {
		rename zip zip9
	}
	else {
	drop 	 if _n==1
	rename 	 v5 zip9
	}
	keep 	 zip9
	gen 	 zip=substr(zip9,1,5)
	replace  zip = subinstr(zip, "-", "",.)
	destring zip, replace
	gen 	 count=1
	collapse (sum) count, by(zip)
	drop 	 if zip==.
	merge 	 1:1 zip using ../zip_cty_cz_crosswalk
	keep 	 if _merge==3
	collapse (sum) count, by(cty)
	gen		 year=`y'
	tempfile temp`y'
	save `temp`y''
}

* stack annual counts together
use `temp1996', clear
forvalues y=1997(1)2015 {
	append using `temp`y''
}

* 1998 data did not come on the excel file so replace as missing
replace count=. if year==1998

* clean up county variable
gen 	county = string(cty,"%05.0f")
drop 	cty

* save data
save 	${root}/data/derived/clinic_counts, replace


