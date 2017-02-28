/***
Purpose: Read in raw census data and produce share 65+ by county
***/

* Set directories
return clear
do `"`c(sysdir_personal)'profile.do"'
global mua $dropbox/mua
set more off 

*Read in raw census data
project, original ("$mua/data/raw_data/census/co-est00int-agesex-5yr.csv")
import delimited "$mua/data/raw_data/census/co-est00int-agesex-5yr.csv", ///
	stringcols(3) encoding(ISO-8859-1) clear
	
*Generate county fips codes for matching
tostring state, gen (st)
g cfips = st+county
drop county 
g county = real(cfips)

*Age group 14-18 is 65+
forvalues i = 2000(1)2010 {
	g old_`i' = popestimate`i' if agegrp>=14 & agegrp<.
}

*Collapse by county
collapse (sum) old* pop*, by(county)

*Generate shares
forvalues i = 2000(1)2010 {
	g over65_`i' = old_`i'/popestimate`i'
}

keep county over65* 
save "$mua/data/derived_data/cty_over_65_shares", replace
project, creates("$mua/data/derived_data/cty_over_65_shares.dta")
