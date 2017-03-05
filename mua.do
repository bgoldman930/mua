/***
Name: Master do-file for the MUA project
Project began January 2017: Kaveh Danesh and Benny Goldman 
***/

set more off
project, doinfo
local pdir=r(pdir)
do `"`c(sysdir_personal)'profile.do"'

*------------------------------------------------------------------------------
*Outside data cleaning
*------------------------------------------------------------------------------

project, do("data_setup/Clean over 65 by county.do")
project, do("data_setup/Clean population by county.do")
project, do("data_setup/Clean infant mortality by county.do")
project, do("data_setup/Clean raw HRSA data.do")
project, do("data_setup/Create crosswalks.do")

*------------------------------------------------------------------------------
*Construct core county level sample
*------------------------------------------------------------------------------

project, do("data_setup/Make treatment and control.do")

*------------------------------------------------------------------------------
*Analyze demographics of treatment and control
*------------------------------------------------------------------------------

project, do("data_setup/Treatment vs control sum stats.do")

*------------------------------------------------------------------------------
*Results
*------------------------------------------------------------------------------

project, do("analysis/Doctor event studies.do")

