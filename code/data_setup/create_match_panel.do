
* create match panel 
cd /Users/Kaveh/Dropbox/mua/raw/ama

set more off 

use /Users/Kaveh/GitHub/mua/data/derived/mua_base, clear
keep if desig_level=="cty"
keep state county year imu 
gen st = string(state,"%02.0f")
gen cty = string(county,"%03.0f")
rename county county2
gen county = st+cty
drop st cty state county2
tempfile temp
save `temp'

use /Users/Kaveh/Dropbox/mua/raw/ama/ama_county_data, clear
destring county, replace
xtset county year
tsfill
gen county2 = string(county,"%05.0f")
drop county
rename county2 county
order county
merge 1:1 county year using ${root}/data/covariates/county_covariates_interpolated_imu
drop if _merge==2
drop _merge
merge 1:1 county year using `temp'
drop if _merge==2
gen desig = (imu!=.)
replace desig = year if desig==1
bys county: egen designation_year=max(desig)
replace designation_year=. if designation_year==0
bys county: gen treated=(designation_year!=.)
drop desig _merge
tempfile temp
save `temp'

* save control counties
keep if treated==0
gen st = substr(county,1,2)
gen cty = substr(county, 3,3)
keep st year cty predicted_imu
rename cty cty_ctrl
rename predicted_imu imu_ctrl 
tempfile temp2
save `temp2'


* now, for each place that got treated, find a place in the same state that did not get treated
* then run a diff-in-diff 
use `temp', clear
keep county year imu predicted_imu designation_year treated 
keep if treated==1 & year==designation_year
gen st = substr(county,1,2)
gen cty = substr(county, 3,3)
order st cty county year
merge m:m st year using `temp2'
order st cty
sort st cty
keep if _merge==3
gen imudiff = abs(predicted_imu-imu_ctrl)
gsort county imudiff
bys county: gen count=_n
keep if count==1
gen county_control = st+cty_ctrl
keep county county_control year 
bys county_control: gen count=_n
keep if count==1 // remove duplicate counties
drop count
save ${root}/data/covariates/treatment_control_pairs, replace


* now merge in doctor counts
use /Users/Kaveh/Dropbox/mua/raw/ama/ama_county_data, clear
encode county, gen(countycode)
tsset countycode year
tsfill, full
bys countycode: replace county=county[_n-1] if county==""
bys countycode: gen count=sum(county!="")
bys countycode: egen max=max(count)
keep if max==25
drop count max countycode
merge 1:1 county year using ${root}/data/covariates/treatment_control_pairs
gen desig = (_merge==3)
replace desig = year if desig==1
bys county: egen designation_year=max(desig)
replace designation_year=. if designation_year==0
bys county: gen treated=(designation_year!=.)
drop desig
keep if treated==1
destring county_control, gen(county_control2)
gen cty = (_merge==3)
replace cty = county_control2 if cty==1
bys county: egen county_control3=max(county_control2)
drop cty
drop county_control county_control2
gen county_control = string(county_control3,"%05.0f")
drop treated county_control3
drop _merge
rename county county_tx
rename tot tot_tx
rename totpc totpc_tx
rename county_control county
sort county_tx year
merge 1:1 county year using /Users/Kaveh/Dropbox/mua/raw/ama/ama_county_data
drop if _merge==2
drop _merge
merge 1:1 county year using ${root}/data/covariates/county_covariates_interpolated, keepusing(pop_ip)
drop if _merge==2
drop _merge
rename county county_ctrl
rename county_tx county
rename pop_ip pop_ip_ctrl
merge 1:1 county year using ${root}/data/covariates/county_covariates_interpolated, keepusing(pop_ip)
rename pop_ip pop_ip_tx
drop if _merge==2
sort county year

* interpolate
by county: ipolate pop_ip_tx year, gen(pop_ip_tx2) epolate
by county: ipolate pop_ip_ctrl year, gen(pop_ip_ctrl2) epolate
drop pop_ip_tx pop_ip_ctrl
rename pop_ip_tx2 pop_ip_tx
rename pop_ip_ctrl2 pop_ip_ctrl
rename county county_tx
sort county_tx year
by county_tx: ipolate tot_tx year, gen(tot_tx_ip) 
by county_tx: ipolate tot year, gen(tot_ctrl_ip) 

gen tot_tx_per_capita=1000*(tot_tx_ip/pop_ip_tx)
gen tot_ctrl_per_capita=1000*(tot_ctrl_ip/pop_ip_ctrl)
gen diff = tot_tx_ip - tot_ctrl_ip
gen diff_pc = tot_tx_per_capita-tot_ctrl_per_capita



*A
gen eit = (year==designation_year)

*B
rename county_tx county
encode county, gen(countycode)
tsset countycode year
gen binpre = (year-designation_year <= -3)
gen binpost = (year-designation_year >= 7)
reg diff_pc binpre l(-2/-2).eit l(0/6).eit binpost i.year, absorb(county) cluster(county)

*C 
regsave, ci
gen t = _n - 7
replace t = t+1 if _n>=6
drop if _n>12
twoway (scatter coef t) ///
(line ci_lower t) ///
(line ci_upper t)

twoway (scatter coef t) ///
(rcap ci_upper ci_lower t)


graph export ${root}/data/covariates/event_study_treatment.pdf



