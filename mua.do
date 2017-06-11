/***
Name: Master do-file for the MUA project
Project began January 2017: Kaveh Danesh and Benny Goldman 
***/

set more off
project, doinfo
local pdir=r(pdir)
do `"`c(sysdir_personal)'profile.do"'

*Make directories
capture mkdir "results/figures"
capture mkdir "results/tables"
capture mkdir "data/raw"
capture mkdir "data/derived"

*------------------------------------------------------------------------------
*Clean MUA data
*------------------------------------------------------------------------------

project, do("code/data_setup/clean_raw_hrsa_data.do")
project, do("code/data_setup/clean_crosswalks.do")
project, do("code/data_setup/build_mua_cty.do")
project, do("code/data_setup/build_mua_mcd.do")
project, do("code/data_setup/build_mua_ct.do")
project, do("code/data_setup/make_mua_assigment_maps.do")
