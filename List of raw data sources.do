/***
Purpose: List sources for raw data

****************************
*AHRF - Area Health Resource File from HRSA
****************************

Description: County panel on health variables, physicians, and other vars
Link: https://datawarehouse.hrsa.gov/data/datadownload.aspx#MainContent_ctl00_gvDD_lbl_dd_topic_ttl_0
Notes:	Downloaded the SAS format and then converted to Stata on Census server

****************************
*Pooled Mortality yyyy-yyyy.txt
****************************
	
Description: Infant mortality by county with broad year groupings (b/c of suppresion)
Link: https://wonder.cdc.gov/mortSQL.html
Steps:
	1. Visit link and choose years of interest
	2. From dropdown choose county 
	3. Select infant age ranges and then all ages	

****************************
*Compressed Mortality yyyy-yyyy.txt
****************************
	
Description: Infant mortality by county and year
Link: https://wonder.cdc.gov/mortSQL.html
Steps:
	1. Visit link and choose years of interest
	2. From dropdown choose county 
	3. Also choose year
	4. Select infant age ranges and then all ages
Notes: These produce the compressed mortality files for infants and appear to be unmasked!
	
****************************
*zcta_tract_rel_10.txt
****************************

Description: 2010 census tract to zcta crosswalk
Link: https://www.census.gov/geo/maps-data/data/zcta_rel_download.html

****************************
*zcta_cousub_rel_10.txt
****************************

Description: 2010 census tract to county subdivision crosswalk
Link: https://www.census.gov/geo/maps-data/data/zcta_rel_download.html

****************************
*zcta_county_rel_10.txt
****************************

Description: 2010 census tract to county crosswalk
Link: https://www.census.gov/geo/maps-data/data/zcta_rel_download.html

****************************
*infmort99to15.txt
****************************

Description: infant mortality data by county

Link: https://wonder.cdc.gov/controller/datarequest/D76;jsessionid=6652AB73F39A132DE1287471192E9337

Steps:
1. Go to https://wonder.cdc.gov/
2. Select "Detailed Mortality"
3. Agree to terms
4. Under Table Layout, group results by County; under Demographics, choose < 1 year

****************************
*co-est00int-agesex-5yr.csv
****************************

Description: Population by age in each county*year
Link: https://www.census.gov/data/datasets/time-series/demo/popest/intercensal-2000-2010-counties.html

****************************
*county_population.dta
****************************

Description: Population by county*year from NBER
Link: http://www.nber.org/data/census-intercensal-county-population.html

****************************
*mua_det.csv
****************************

Description: Panel of geographies assigned MUA status
Link: HRSA website [doc in folder]

****************************
*zcta_xx.csv
****************************

Description: Census geography crosswalks
Link: https://www.census.gov/geo/maps-data/data/zcta_rel_download.html

****************************
*cty_covars.dta
****************************

Description: Covariates by county (Online Data Table 4 from Movers)
Link: http://www.equality-of-opportunity.org/data/causal/nbhds_online_data_table4.dta

****************************
*county_list.dta
****************************

Description: List of all counties from Michael Stepner's shape files
Link: http://files.michaelstepner.com/geo_county2000_creation.zip

