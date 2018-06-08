set more off 

/*

This file creates three panels with doctor counts for subsequent event studies:

1. a county-level panel, 1991-2015, indicating counties designated as muas at the county level
2. a tract-level panel, 2001-2015, indicating tracts designated as muas at the county or tract level
3. a county-level panel, 1991-2015, indicating counties designated as muas at the tract, mcd, or county level

*/

* 0. preliminary: create roster of counties ever designated at ct or mcd level 

* load dataset
use 	${root}/data/derived/mua_base, clear

* keep relevant rows
keep 	if desig_level=="ct" | desig_level=="mcd"

* keep relevant cols
keep 	state county

* convert to string fips
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop 	st cty state county2
save 	${root}/data/derived/counties_with_ct_or_mcd


* 1. create county-level panel

* load file
use 	${root}/data/derived/mua_base, clear

* keep muas designated at county level only
keep 	if desig_level=="cty"

* keep relevant vars
keep 	state county year imu 

* generate string version of county fips
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
rename 	county county2
gen 	county = st+cty
drop 	st cty state county2

* save as tempfile
tempfile temp
save 	`temp'

* load county-level doctor counts
use 	${root}/data/raw/ama/ama_county_data, clear

* make into panel
destring county, replace
xtset 	 county year
tsfill

* generate string version of county fips (for merge)
gen 	county2 = string(county,"%05.0f")
drop 	county
rename	county2 county
order 	county

* merge panel to muas
merge 	1:1 county year using `temp'
drop 	if _merge==2

* create designation_year and ever_treated variables
gen 	desig = (imu!=.)
replace desig = year if desig==1
bys 	county: egen designation_year=max(desig)
replace designation_year=. if designation_year==0
bys 	county: gen treated=(designation_year!=.)
drop 	desig _merge

* merge in imu score and population
merge 	1:1 county year using ${root}/data/derived/county_covariates_interpolated_imu, keepusing(predicted_imu pop_ip)
drop 	_merge

* create indicator for non-county-level treatment (i.e. tract- or mcd-level)
merge 	m:1 county using ${root}/data/derived/counties_with_ct_or_mcd
gen 	ct_or_mcd = (_merge==3)
drop 	_merge

* save 
save ${root}/data/derived/mua_panel, replace


* 2. create tract-level panel

* load data
use 	${root}/data/derived/mua_base, clear

* keep relevant variables
keep 	state county tract year imu desig_level

* keep only muas designated at tract or cty level
drop 	if desig_level=="mcd"

* generate string versions of variables
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
gen 	tr = string(tract,"%06.0f")
drop 	county tract
gen 	county = st+cty if desig_level=="cty"
gen 	tract = st+cty+tr if desig_level=="tract"

* keep relevant variables
keep 	desig_level year county tract

* keep relevant years
keep 	if year>=2001 & year<=2015

* rename year variable to avoid conflict during merge
rename 	year designation_year

* save as tempfile
tempfile 	temp
save 		`temp'

* save two different versions of files
keep 	if desig_level=="tract"
drop	county
save	${root}/data/derived/mua_panel_tract, replace
use 	`temp', clear
keep 	if desig_level=="cty"
drop	tract
save	${root}/data/derived/mua_panel_county, replace


* load tract-level doctor counts
use 	${root}/data/raw/ama/ama_tract_data, clear

* make temporary fix until we get data for correct year
replace year=2001 if year==2000

* generate primary care doctor count
gen 	totpc = fp+gp+im+mpd+fpg+img+pd+obg+gyn+obs

* keep relevant variables
keep 	tract year tot totpc

* turn into balanced panel
destring	tract, replace
xtset 		tract year
tsfill
fillin 		tract year
drop 		_fillin

* generate string version of tract
gen 	tract2 = string(tract,"%011.0f")
drop 	tract
rename 	tract2 tract
order 	tract

* generate string version of county
gen 	county = substr(tract, 1, 5)
order	county tract

* replace missing data with zeros in years where we have data
replace tot=0 if tot==. & mod(year,2)==1

* merge in tract-level muas
merge 	m:1 tract using ${root}/data/derived/mua_panel_tract
drop	if _merge==2
drop 	_merge
rename	desig_level desig_level_tr
rename	designation_year designation_year_tr

* merge in county-level muas
merge 	m:1 county using ${root}/data/derived/mua_panel_county
drop	if _merge==2
drop 	_merge

* consolidate desig_level and designation_year variables
replace desig_level = desig_level_tr if desig_level==""
replace designation_year = designation_year_tr if designation_year==.
drop	desig_level_tr designation_year_tr

save 	${root}/data/derived/mua_panel_tract, replace




* 3. create county-level panel indicating mua designation at any geographical level

* load data
use 	${root}/data/derived/mua_base, clear

* keep relevant variables
keep 	state county tract year imu desig_level

* generate string versions of variables
gen 	st = string(state,"%02.0f")
gen 	cty = string(county,"%03.0f")
gen 	tr = string(tract,"%06.0f")
drop 	county tract
gen 	county = st+cty
drop	st cty tr

* keep relevant variables
keep 	desig_level year county
order	county year desig_level

* keep relevant years
keep 	if year>=1991

* rename year variable to avoid conflict during merge
rename 	year designation_year

* drop duplicates at county-year level
bys 	county designation_year: gen count=_n
keep 	if count==1
drop 	count
sort 	county designation_year

* drop all counties that got designated more than once in separate years
bys 	county: gen count=_n
bys		county: egen max=max(count)
keep 	if max==1
drop	count max
sort	county designation_year

* save as tempfile
tempfile 	temp
save 		`temp'


* load county-level doctor counts
use 	${root}/data/raw/ama/ama_county_data, clear

* make temporary fix until we get data for correct year
replace year=2001 if year==2000

* turn into balanced panel
destring	county, replace
xtset 		county year
tsfill
fillin 		county year
drop 		_fillin

* generate string version of tract
gen 	county2 = string(county,"%05.0f")
drop 	county
rename 	county2 county
order 	county

* replace missing data with zeros in years where we have data
replace tot=0 if tot==. & mod(year,2)==1

* merge in muas
merge 	m:1 county using `temp'
drop	if _merge==2
drop 	_merge

* merge in population
merge 	1:1 county year using ${root}/data/derived/county_covariates_interpolated_imu, keepusing(predicted_imu pop_ip)
drop 	if _merge==2
sort	county year
by 		county: ipolate pop_ip year, gen(pop_ep) epolate
drop	_merge pop_ip

save ${root}/data/derived/mua_panel_allgeo, replace

