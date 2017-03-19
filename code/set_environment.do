clear all
set more off
pause on

global root "$git/mua"

*Stepner features below, could use if I wanted
*adopath ++ "$root/code/ado_ssc"
*adopath ++ "$root/code/ado"
*confirmcmd using "$root/code/requirements.txt"  // check that required commands are installed

* Disable project (since running do-files directly)
cap program drop project
program define project
	di "Project is disabled, skipping project command. (To re-enable, run -{stata program drop project}-)"
end
