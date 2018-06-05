/***
Purpose: Build tract level data set from EOP clean data
***/


*---------------------------------------------------------------------
*Clean Alex Jenni's long covariates
*---------------------------------------------------------------------

use "${root}/data/raw/covariates_tract_long.dta", clear

rename (state10 county10 tract10) (state county tract)

*Keep a subset of the variables
keep ///
	state 				county				tract 				year ///
	pop popdensity 		hhinc_mean 			poor_share 			share_black ///
	share_hisp 			share_asian 		singleparent_share 	median_rent ///
	pct_foreign 		household_size 		pct_divorced 		pct_married ///
	median_value 		lfp 				lfp_m 				lfp_w ///
	pct_manufacturing 	lead_share 			frac_kids_eng_only 	frac_kids_span ///
	frac_less_hs 		frac_less_hs_male frac_less_hs_female 	frac_coll_plus ///
	frac_coll_plus_male frac_coll_plus_female 					share_innercity ///
	share_outercity 	share_rural 		share_owner 		share_renter ///
	poor_share_white 	poor_share_black 	poor_share_asian 	poor_share_hispanic ///
	med_hhinc_white 	med_hhinc_black 	med_hhinc_asian 	med_hhinc_hispanic ///
	share_seniors
order ///
	state 				county				tract 				year ///
	pop popdensity 		hhinc_mean 			poor_share 			share_black ///
	share_hisp 			share_asian 		singleparent_share 	median_rent ///
	pct_foreign 		household_size 		pct_divorced 		pct_married ///
	median_value 		lfp 				lfp_m 				lfp_w ///
	pct_manufacturing 	lead_share 			frac_kids_eng_only 	frac_kids_span ///
	frac_less_hs 		frac_less_hs_male frac_less_hs_female 	frac_coll_plus ///
	frac_coll_plus_male frac_coll_plus_female 					share_innercity ///
	share_outercity 	share_rural 		share_owner 		share_renter ///
	poor_share_white 	poor_share_black 	poor_share_asian 	poor_share_hispanic ///
	med_hhinc_white 	med_hhinc_black 	med_hhinc_asian 	med_hhinc_hispanic ///
	share_seniors

compress
save "${root}/data/covariates/tract_covariates.dta", replace

*---------------------------------------------------------------------
*Clean Alex Jenni's wide covariates
*---------------------------------------------------------------------

use "${root}/data/raw/covariates_tract_wide.dta", clear
rename (state10 county10 tract10) (state county tract)
save "${root}/data/covariates/tract_covariates_wide.dta", replace
