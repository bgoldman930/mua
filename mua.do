/***
Name: Master do-file for the MUA project
Project began January 2017: Kaveh Danesh and Benny Goldman 
***/

set more off
project, doinfo
local pdir=r(pdir)
do `"`c(sysdir_personal)'profile.do"'

*Make directories
capture mkdir "`pdir'/results/figures"
capture mkdir "`pdir'/results/tables"
capture mkdir "`pdir'/data/raw"
capture mkdir "`pdir'/data/derived"

*------------------------------------------------------------------------------
*Outside data cleaning
*------------------------------------------------------------------------------

project, do("code/data_setup/clean_over_65_by_county.do")
project, do("code/data_setup/clean_population_by_county.do")
project, do("code/data_setup/clean_infant_mortality_by_county.do")
project, do("code/data_setup/clean_raw_hrsa_data.do")
project, do("code/data_setup/create_crosswalks.do")

*------------------------------------------------------------------------------
*Construct core county level sample
*------------------------------------------------------------------------------

project, do("code/data_setup/make_treatment_and_control.do")

*------------------------------------------------------------------------------
*Analyze demographics of treatment and control
*------------------------------------------------------------------------------

project, do("code/data_setup/treatment_vs_control_sum_stats.do")

*------------------------------------------------------------------------------
*Results
*------------------------------------------------------------------------------

project, do("code/analysis/doctor_event_studies.do")

