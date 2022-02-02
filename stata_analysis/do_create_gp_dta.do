***** This .do file is ran from on_ms_ukb_v2_1.do and creates .dta files based on cases retrieved from the UKBB GP records 

clear

******* MS cases from the GP records
import delimited using "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/ms_thin_cases.tsv"

* date into readable format
gen event_date_MS = date(event_dt, "YMD")
format event_date_MS %td

sort  n_eid event_date_MS  /*Order records by admission date*/
bysort n_eid: generate order_gp = _n /* Generate a variable with the order of the admission date */
keep if order_gp==1 /* Keep earliest admission for each person */

drop value1 value2 value3 event_dt order_gp /* these values are mostly empty and their meaning is not specified */

generate gp_flag_MS = 1 

rename read_2 read_2_ms_gp
rename read_3 read_3_ms_gp

save "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/ms_gp_only.dta", replace
clear

******* aberrant ON cases deemed unsuitable by TB and AP 

*Importing list of individuals with ON diagnoses from the file
import delimited using "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/aber_on_ukb_cases.tsv"

gen event_date_aber_on = date(event_dt, "YMD")
format event_date_aber_on %td

sort  n_eid event_date_aber_on  /*Order records by admission date*/
bysort n_eid: generate order_gp = _n /* Generate a variable with the order of the admission date */
keep if order_gp==1 /* Keep earliest admission for each person */

generate gp_aber_ON = 1
drop value1 value2 value3 event_dt order_gp data_provider /* these values are mostly empty and their meaning is not specified */

rename read_2 read_2_aber_on
rename read_3 read_3_aber_on

save "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/nutrit_on_to_remove.dta", replace
clear

******* Creating True ON file 

import delimited using "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/on_thin_cases.tsv"

gen event_date_ON = date(event_dt, "YMD")
format event_date %td
sort  n_eid event_date  /*Order records by admission date*/
bysort n_eid: generate order_gp = _n /* Generate a variable with the order of the admission date */
keep if order_gp==1 /* Keep earliest admission for each person */


generate gp_flag_ON = 1 

drop value1 value2 value3 event_dt order_gp /* these values are mostly empty and their meaning is not specified */


save "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/on_diag_gp.dta", replace
