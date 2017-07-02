/***
Purpose: Clean raw MUA data
***/

* Set directories
return clear
capture project, doinfo
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'  // using -project-
else {  // running directly
	if ("${mua}"=="") do `"`c(sysdir_personal)'profile.do"'
	do "${mua}/code/set_environment.do"
}
set more off 


* I. CREATE DESIGNATION YEAR X MO DATASET FOR MUAs
** one row per MUA
** note this dataset contains both MUAs and MUPs; can drop MUPs later if necessary
project, original("${root}/data/raw/mua_det.csv")
insheet using "${root}/data/raw/mua_det.csv", comma clear
g date = date(v53, "YMD")
format date %tdMon-YY
g year = year(date)
g month = month(date)
g day = day(date)
order date year month day
sort date

* Note an MUA can be a
** minor civil division (MCD)
** single county (SCTY)
** census tract (CT)
* Organize all three geocodes:
rename v55 geo_type
rename minorcivildivisionfipscode mcd
rename commonstatecountyfipscode county
rename censustract ct
sort year month geo_type
order year month geo_type mcd county ct
save "${root}/data/derived/mua", replace
project, creates("${root}/data/derived/mua.dta")

