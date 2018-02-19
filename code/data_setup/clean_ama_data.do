cd /Users/Kaveh/Dropbox/mua/raw/ama

set more off 

* CLEAN TRACT DATA

* load in each annual file and clean
foreach y of numlist 2000 2003(2)2015 {
	insheet using QUO-09149-Y3W5B2#1_`y'.csv, comma clear
	drop if censustract=="Total"
	rename v??? tot
	gen year=`y'
	tempfile temp`y'
	save `temp`y''
}

* append annual files
use `temp2000', clear
forvalues y=2003(2)2015{
	append using `temp`y''
}

* replace missing with zero
foreach var of varlist a-cli {
	replace `var'=0 if `var'==.
}

* keep only total docs for now
rename censustract tract
*keep tract year tot

* save
order tract year
sort tract year
save ama_tract_data, replace

* CLEAN COUNTY FILE

* load in each annual file and clean
set more off
forvalues y = 1991(2)1999 {
	insheet using QUO-09149-Y3W5B2#2_`y'.csv, comma clear
	drop if fipscounty=="TOTAL" | fipscounty=="Total"
	rename v??? tot
	gen year=`y'
	tempfile temp`y'
	save `temp`y''
}

* append annual files
use `temp1991', clear
forvalues y=1993(2)1999{
	append using `temp`y''
}

* replace missing with zero
foreach var of varlist a-pan {
	replace `var'=0 if `var'==.
}

* clean county variable 
gen county = substr(fipscounty,1,6)
drop fipscounty
replace county = subinstr(county,"-","",.)
order county year
sort county year

* save as tempfile
tempfile tempcty
save `tempcty'

* load tract data (2000-2015) and collapse to county level
use ama_tract_data, clear
gen county = substr(tract, 1, 5)
drop tract
order county year
collapse (sum) a-cli, by(county year)

* append collapsed tract data (2000-2015) to county data (1991-2000)
append using `tempcty'

* create primary care doctor count
gen totpc = fp+gp+im+mpd+fpg+img+pd+obg
* keep only total docs for now
keep county year tot totpc

* save
sort county year
save ama_county_data, replace

