****** This file retrieves diagnoses from rawer UKBB HESIN data. A description of the databases can be found here https://biobank.ndph.ox.ac.uk/ukb/label.cgi?id=2000


foreach disease in "MS""ON"{

clear 
set maxvar 64000

import delimited "/slade/projects/UKBB/phenotype_data/master/main_data/HES_data/hesin_diag150920.txt"
	
	if "`disease'" == "MS" {
		local dis="MS"
		local icd10 = "G35"
	}
	
	
	if `"`disease'"' == "ON" {
		local dis="ON"
		local icd10="H46"
	}
	
	generate hes_flag_`dis' = .
	
	foreach i of local icd10 {
		display "Processing `i'"
		replace hes_flag_`dis' = 1 if regexm(diag_icd10,"^`i'.*")==1 /* Make flag to identify all records with code in user's list */
	}

	keep if hes_flag_`dis' == 1 

	save "/slade/home/pl450/MS_GRS_overall_1412/hes_data_on_ms/`dis'_hesin_1509.dta", replace 


***** Adding file contain date and selecting the earliest of dates *************************


clear 
import delimited "/slade/projects/UKBB/phenotype_data/master/main_data/HES_data/hesin150920.txt"


merge 1:m eid ins_index using "/slade/home/pl450/MS_GRS_overall_1412/hes_data_on_ms/`dis'_hesin_1509.dta"
keep if _merge == 3
keep if hes_flag_`dis' ==1

generate addate = date(admidate, "DMY") /* Generate admission date variable */
format addate %td /* Reformat the admission date to date format */
generate dischdate = date(disdate, "DMY") /* Generate discharge date variable */
format dischdate %td /* Reformat the discharge date to date format */
generate epistdate = date(epistart, "DMY") /* Generate epi start variable */
format epistdate %td /* Reformat the epi start to date format */
generate epienddate = date(epiend, "DMY") /* Generate epi end variable */
format epienddate %td /* Reformat the epi end to date format */

generate date_1st_`dis' = min(addate,dischdate,epistdate,epienddate) /* Find earliest of dates */
format date_1st_`dis' %td /* Reformat the epi end to date format */

sort eid date_1st_`dis' /*Order records by admission date*/
bysort eid: generate order=_n /* Generate a variable with the order of the admission date */
keep if order==1 /* Keep the first admission date */

*** Renaming variables for later merges with other files
rename diag_icd10 diag_icd10_`dis'
rename eid n_eid
rename dsource dsource_`dis'
rename mainspef mainspef_`dis'
rename mainspef_uni mainspef_uni_`dis'
rename carersi carersi_`dis'
rename date_1st_`dis' date_1st_hes_`dis'

keep n_eid dsource_`dis' mainspef_`dis' mainspef_uni_`dis' carersi_`dis' date_1st_hes_`dis' diag_icd10_`dis' hes_flag_`dis' /* Keep relevant variables */

save "/slade/home/pl450/MS_GRS_overall_1412/hes_data_on_ms/`dis'_hes_2609.dta", replace
		
}
