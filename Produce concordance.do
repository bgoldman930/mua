/***
Purpose: Produce concordance table
***/

cap log close
set more off
log using "$git/mua/concordance.log", replace
project mua, list(concordance)
log off
