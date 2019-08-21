/***
Name: Master do-file for the MUA project
Project began January 2017: Kaveh Danesh and Benny Goldman 
***/

drop _all
set more off
global root "$git/mua"
adopath + "${root}/code/ado"
set scheme bgplain

*------------------------------------------------------------------------------
*Create and clean directories
*------------------------------------------------------------------------------

*Clean out the results and derived data directories
capture shell rm -r "${root}/results"
capture shell rm -r "${root}/data/derived"
capture shell rm -r "${root}/data/covariates"

*Make directories
capture mkdir "${root}/results"
capture mkdir "${root}/results/figures"
capture mkdir "${root}/results/tables"
capture mkdir "${root}/data/derived"
capture mkdir "${root}/data/covariates"

*------------------------------------------------------------------------------
*Build code
*------------------------------------------------------------------------------

*Covariates
do "${root}/code/data_setup/county_infant_mortality.do"
do "${root}/code/data_setup/county_mortality.do"
do "${root}/code/data_setup/ahrf.do"

*Set up using RD in 1978
do "${root}/code/data_setup/county_with_covars.do"

*Try the RD and the dif n' dif
do "${root}/code/analysis/rd_dnd_1978.do"
do "${root}/code/analysis/map_of_predictions.do"
do "${root}/code/analysis/naiive regs.do"

* Try the basic DID (8-2019) now that I understand econometrics
