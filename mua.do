/***
Name: Master do-file for the MUA project
Project began January 2017: Kaveh Danesh and Benny Goldman 
***/

drop _all
set more off
global root "$git/mua"

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
do "${root}/code/covariates/county_infant_mortality.do"
do "${root}/code/covariates/county_population.do"
do "${root}/code/covariates/tract_covariates.do"
do "${root}/code/covariates/ahrf.do"

*Data setup
do "${root}/code/data_setup/clean_raw_mua_data.do"
do "${root}/code/data_setup/clean_ama_data.do" 
do "${root}/code/data_setup/create_covariates_panel.do"
do "${root}/code/data_setup/create_match_panel.do"
*do "${root}/code/data_setup/predict_imu_scores.do" // XX This doesn't appear to produce output

*Descriptive statistics
do "${root}/code/descriptive/maps.do"
do "${root}/code/descriptive/corrplot.do"
do "${root}/code/descriptive/bin_pov.do"
do "${root}/code/descriptive/le_docs.do"
do "${root}/code/descriptive/trends.do"
do "${root}/code/descriptive/ranks.do"
do "${root}/code/descriptive/specialists.do"



