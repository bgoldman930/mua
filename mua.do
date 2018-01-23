/***
Name: Master do-file for the MUA project
Project began January 2017: Kaveh Danesh and Benny Goldman 
***/

set more off
project, doinfo
local pdir=r(pdir)
if (_rc==0 & !mi(r(pname))) global root `r(pdir)'
do `"`c(sysdir_personal)'profile.do"'

*Make directories
capture mkdir "results"
capture mkdir "results/figures"
capture mkdir "results/tables"
capture mkdir "data"
capture mkdir "data/raw"
capture mkdir "data/derived"
capture mkdir "data/covariates"


*------------------------------------------------------------------------------
*Clean MUA data
*------------------------------------------------------------------------------

*Covariates
project, do("code/covariates/county_infant_mortality.do")
project, do("code/covariates/county_population.do")
project, do("code/covariates/tract_covariates.do")
project, do("code/covariates/ahrf.do")

*MUA Data setup
project, do("code/data_setup/clean_raw_mua_data.do")

