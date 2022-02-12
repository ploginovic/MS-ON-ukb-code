/* This file is recreating stata phenotypic analysis in a more comprehensive way
		*/
clear 

******* Part 1 ******* Primary Care records analysis
run "/slade/home/pl450/MS_GRS_overall_1412/stata_analysis/do_create_gp_dta.do"

run "/slade/home/pl450/MS_GRS_overall_1412/stata_analysis/dis_hesin_create_dta.do"

******* Part 2 ******* Loading raw phenotype, first occurence, hes and gp records

clear 
set maxvar 64000 

* importing final .tsv file containing calculated GRS
import delimited "/slade/home/pl450/MS_GRS_overall_1412/summedchr_nonhla_msgrs_p000001.tsv"

* The following block uses raw phenotype data, containing self-reported diseases, icd10 diagnoses and many covariates, which are described in a separate file

merge m:1 n_eid using "/slade/local/UKBB/phenotype_data/master/main_data/raw_data_2019.dta", keepusing(n_eid ts_53_0_0 n_52_0_0 n_31_0_0 n_34_0_0 n_189_0_0 n_22011_0_0 n_22012_0_0 n_21001_0_0 n_20002_* n_20009_* n_21000_0_0 n_22001_0_0 n_20116_0_0 s_40001_* s_40002_* ts_40000_* s_41204* n_22009_0_1-n_22009_0_8 n_22005_0_0 n_22004_0_0 n_22006_0_0 n_22010_0_0 n_100021_*) //Consider removing 41202 and similar, as no date is provided

keep if _merge ==3 
drop _merge 

* Adding first occurence data, which is supposed to capture all sources of diagnoses
merge 1:1 n_eid using "/slade/projects/UKBB/phenotype_data/master/main_data/ukb_first_occurrences.dta", keepusing(n_eid n_131197_0_0 ts_131196_0_0 /* ON data-fields */ n_131043_0_0 ts_131042_0_0 /*MS*/) generate(first_occ_merge)

keep if first_occ_merge ==3 
drop first_occ_merge

* Adding Mike's patients from the GP records, produced by .do code in line 6 of this file
merge m:1 n_eid using "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/on_diag_gp.dta", nogenerate

merge 1:1 n_eid using "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/ms_gp_only.dta", nogenerate

merge 1:1 n_eid using "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/aber_on_to_remove.dta", nogenerate 

* merging hesin files, produced in line 8 of this code
merge 1:1 n_eid using "/slade/home/pl450/MS_GRS_overall_1412/hes_data_on_ms/ON_hes_2609.dta", generate (hes_ON_merge)
drop if hes_ON_merge ==2 

merge 1:1 n_eid using "/slade/home/pl450/MS_GRS_overall_1412/hes_data_on_ms/MS_hes_2609.dta", generate (hes_MS_merge)
drop if hes_MS_merge ==2 

*** Renaming variables
******** Cleaning-up data ********

rename n_31_0_0 Sex
rename n_22001_0_0 genetic_sex
rename ts_53_0_0 enrol_date
rename n_34_0_0 YOB
rename n_52_0_0 MOB
rename n_21001_0_0 BMI
rename n_22010_0_0 exclusion
rename n_22006_0_0 white_british
rename n_20116_0_0 smoking_status
rename n_21000_0_0 ethnic_background
rename n_189_0_0 TDI

rename n_22009_0_1 PC1
rename n_22009_0_2 PC2
rename n_22009_0_3 PC3
rename n_22009_0_4 PC4
rename n_22009_0_5 PC5
rename n_22009_0_6 PC6
rename n_22009_0_7 PC7
rename n_22009_0_8 PC8

** Dropping participants 
drop if exclusion ==1
drop if Sex ==. & genetic_sex==.

* Sorting by genetic relatedeness pairings and dropping one of each pair if kinship coefficient > 0.0844
sort n_22011_0_0 
bysort n_22011_0_0: generate order_kin= _n if n_22011_0_0 !=.
drop if order_kin >= 2 & n_22012_0_0 > 0.0844 & n_22011_0_0!=.
drop order_kin 


** Calculating dummy DOB which will be used in date analysis

gen DOB = mdy(MOB, 15, YOB)
format DOB %td

generate age_in_years = datediff(DOB, enrol_date, "y")
generate age_in_months = datediff(DOB, enrol_date, "m")

generate enrol_age = datediff(DOB, enrol_date, "m")
generate enrol_age_years = datediff(DOB, enrol_date, "y")


******* Part 3: analysing imported data for diagnoses and
//TODO: consider renaming variables first so that DOB etc can be used in the loop 

foreach disease in "MS" "ON"{
	
	if "`disease'" == "MS" {
		local dis="MS"
		local icd10 = "G35"
		local self = "1261"
		local fo_field = "n_131043_0_0"
		local fo_date = "ts_131042_0_0"
		dis "`dis'"
	}
	
	if `"`disease'"' == "ON" {
		local dis="ON"
		local icd10="H46"
		local self="1435"
		local fo_field = "n_131197_0_0"
		local fo_date = "ts_131196_0_0"
		dis "`dis'" "`icd10'" "`self'"
	}
	
*** Looking through self-reported diagnoses	
	generate sr_`dis'=.
	generate sr_flag_`dis'=.
	generate age_1st_sr_`dis'=.

	foreach v of varlist n_20002_* {
			local age_var= regexr("`v'","n_20002_","n_20009_")  /* Create a variable with the name of the relevant age variable */
			display "Processing `age_var'"
		foreach sr of local self {
			replace sr_`dis'=`v' if `v'==`sr' & `age_var'<age_1st_sr_`dis' & `age_var'!=. & `age_var'>0 /* Replace the self-reported disease variable if in the list of codes to find and earlier diagnosis age */
			replace sr_flag_`dis'=1  if `v'==`sr' & `age_var'<age_1st_sr_`dis' & `age_var'!=. & `age_var'>0 /* Replace the self-reported disease flag if in the list of codes to find and earlier diagnosis age */
			replace age_1st_sr_`dis'= `age_var' if `v'==`sr' & `age_var'<age_1st_sr_`dis' & `age_var'!=. & `age_var'>0  /* Replace the age of disease with the self-reported code if in the list of codes to find nd earlier diagnosis age  */
		}
	}

*** adding first-occurrence diagnoses and dates 
generate fo_flag_`dis' =.
replace fo_flag_`dis' = 1 if `fo_field' !=. & `fo_date' !=.

rename `fo_date' date_1st_fo_`dis'

* Removing 'special' dates of first occurre, such 02/02/1902 and 0/3/03/1903, both of which are before DOB 
replace date_1st_fo_`dis'=. if date_1st_fo_`dis' < DOB & date_1st_fo_`dis' !=.



generate age_fo_`dis'_months = datediff(DOB, date_1st_fo_`dis', "m")

generate age_sr_`dis'_months = round(age_1st_sr_`dis' * 12)

generate age_hes_`dis'_months = datediff(DOB, date_1st_hes_`dis', "m")



	generate sr_flag_`dis'_inc=0   
	replace sr_flag_`dis'_inc=sr_flag_`dis' if age_sr_`dis'_months > age_in_months & age_in_months !=. & age_sr_`dis'_months !=. /* Incident disease at age older than age at recruitment */

	generate sr_flag_`dis'_prev=0
	replace sr_flag_`dis'_prev=sr_flag_`dis' if age_sr_`dis'_months <= age_in_months & age_in_months !=. & age_sr_`dis'_months !=.  /* Prevalent disease at age younger or the same as age at recruitment */
	
	
	generate hes_flag_`dis'_inc=0
	replace hes_flag_`dis'_inc=hes_flag_`dis' if date_1st_hes_`dis' > enrol_date & enrol_date !=. & date_1st_hes_`dis'!=. /* Incident disease date after date of recruitment */

	generate hes_flag_`dis'_prev=0
	replace hes_flag_`dis'_prev=hes_flag_`dis' if date_1st_hes_`dis' <= enrol_date & enrol_date !=. & date_1st_hes_`dis'!=. /* Incident disease date after date of recruitment */
	
	
	generate fo_flag_`dis'_inc = 0
	replace fo_flag_`dis'_inc = fo_flag_`dis' if age_fo_`dis'_months > age_in_months & age_in_months!=. & age_fo_`dis'_months !=. /* First-occurence date after age of recruitment */
	
	generate fo_flag_`dis'_prev = 0
	replace fo_flag_`dis'_prev = fo_flag_`dis' if age_fo_`dis'_months <= age_in_months & age_in_months!=. & age_fo_`dis'_months >0
	
	
	
	generate gp_flag_`dis'_prev=0
	replace gp_flag_`dis'_prev= gp_flag_`dis' if event_date_`dis' <= enrol_date & enrol_date !=. & event_date_`dis'!=. & event_date_MS > DOB

	generate gp_flag_`dis'_inc=0
	replace gp_flag_`dis'_inc = gp_flag_`dis' if event_date_`dis' > enrol_date & enrol_date !=. & event_date_`dis' !=. /* Incident disease date after date of recruitment */

	
	generate `dis'_any=.
	replace `dis'_any=0 if sr_flag_`dis'_inc==0  & fo_flag_`dis'_inc == 0 & hes_flag_`dis'_inc==0 & gp_flag_`dis'_inc ==0 & sr_flag_`dis'_prev==0 & fo_flag_`dis'_prev==0 & hes_flag_`dis'_prev==0 & gp_flag_`dis'_prev ==0
	replace `dis'_any=1 if (sr_flag_`dis'_inc==1 | fo_flag_`dis'_inc==1 | hes_flag_`dis'_inc==1 | gp_flag_`dis'_inc==1 | sr_flag_`dis'_prev==1 | fo_flag_`dis'_prev==1 | hes_flag_`dis'_prev==1  | gp_flag_`dis'_prev ==1) 
	
	
	generate `dis'_prev=.
	replace `dis'_prev=0 if `dis'_any !=0 /*&  sr_flag_`dis'_inc==0 & fo_flag_`dis'_inc==0 & hes_flag_`dis'_inc==0 &  sr_flag_`dis'_prev==0 & fo_flag_`dis'_prev==0 & hes_flag_`dis'_prev==0 */
	replace `dis'_prev=1 if (sr_flag_`dis'_prev==1 | fo_flag_`dis'_prev==1 | hes_flag_`dis'_prev==1 | gp_flag_`dis'_prev ==1)
	
	
	generate `dis'_inc=.
	replace `dis'_inc=0 if sr_flag_`dis'_inc==0  & fo_flag_`dis'_inc==0 & hes_flag_`dis'_inc==0 &  gp_flag_`dis'_inc ==0 & sr_flag_`dis'_prev==0 &  fo_flag_`dis'_prev==0 & hes_flag_`dis'_prev==0 & gp_flag_`dis'_prev ==0
	
	replace `dis'_inc=1 if (sr_flag_`dis'_inc==1 | fo_flag_`dis'_inc==1 | hes_flag_`dis'_inc==1 | gp_flag_`dis'_inc ==1) & (`dis'_prev ==0)
	
	
	****** Analysing disease time, separate for each source and inc/prev case
	
	generate inc_time_`dis'_fo =.
	replace inc_time_`dis'_fo = datediff(enrol_date, date_1st_fo_`dis', "m") if fo_flag_`dis'_inc == 1
	
	generate prev_time_`dis'_fo =.
	replace prev_time_`dis' = datediff(enrol_date, date_1st_fo_`dis', "m") if fo_flag_`dis'_prev==1 
	
	generate inc_time_`dis'_hes =.
	replace inc_time_`dis'_hes = datediff(enrol_date, date_1st_hes_`dis', "m") if hes_flag_`dis'_inc ==1
	
	generate prev_time_`dis'_hes=.
	replace prev_time_`dis'_hes = datediff(enrol_date, date_1st_hes_`dis', "m") if hes_flag_`dis'_prev==1 
	
	generate inc_time_`dis'_sr =.
	replace inc_time_`dis'_sr = round(age_sr_`dis'_months - age_in_months) if sr_flag_`dis'_inc ==1
	
	generate prev_time_`dis'_sr=.
	replace  prev_time_`dis'_sr = round(age_sr_`dis'_months - age_in_months) if sr_flag_`dis'_prev ==1 
	
	generate inc_time_`dis'_gp =.
	replace inc_time_`dis'_gp = datediff(enrol_date, event_date_`dis', "m") if gp_flag_`dis'_inc ==1

	generate prev_time_`dis'_gp =.
	replace prev_time_`dis'_gp = datediff(enrol_date, event_date_`dis', "m") if gp_flag_`dis'_prev==1
	
	
*** Selecting minimal date for inc/prev from all data sources
	generate `dis'_inc_time =. 
	replace `dis'_inc_time = min(inc_time_`dis'_fo, inc_time_`dis'_hes, inc_time_`dis'_sr, inc_time_`dis'_gp) if `dis'_inc == 1
	
	generate `dis'_prev_time=.
	replace `dis'_prev_time = min(prev_time_`dis'_fo, prev_time_`dis'_hes, prev_time_`dis'_sr, prev_time_`dis'_gp) if `dis'_prev ==1 
	
	
	generate earliest_`dis' = min(`dis'_prev_time, `dis'_inc_time) if `dis'_any ==1

	generate aao_`dis' =.
	replace aao_`dis' = enrol_age + earliest_`dis' if `dis'_any ==1 /* This is true, as enrol_age is a positive value, prev_time_ON is a negative intiger (months before enrol_date), and inc_time_ON is a positive intiger */
}
* Removing one case with MS self reported at 0.5 years 
drop if aao_MS < 12*15

*removing cases with aberrant ON cases based on aber_on_ukbcodes.csv 
drop if gp_aber_ON ==1 
	
*** Creating a variable to summarize present diagnoses 
generate ON_group = "" 
format ON_group %9s
replace ON_group = "ON only" if ON_any==1 & MS_any ==0
replace ON_group = "MS only" if MS_any ==1 & ON_any ==0
replace ON_group = "Controls" if MS_any ==0 & ON_any ==0 
replace ON_group = "MS-ON" if MS_any ==1 & ON_any ==1 


*** For MS-ON, creating two variables that will show which diagnosis came first
generate first_MS =.
replace first_MS = 1 if ON_any==1 & MS_any ==1 & (earliest_MS < earliest_ON)

generate first_ON =.
replace first_ON = 1 if ON_any ==1 & MS_any ==1 & (earliest_MS > earliest_ON)

generate simult_MS_ON =.

*** The following lists generated by hand inspection if dates (month approx) coincide. Command used `list n_eid date_1st_fo_ON date_1st_hes_ON event_date_ON age_1st_sr_ON enrol_date earliest_ON earliest_MS date_1st_fo_MS date_1st_hes_MS event_date_MS  age_1st_sr_MS if ON_any ==1 & first_MS !=1 & first_ON !=1 & MS_any ==1'

local identical_time = "1349405 1686614 1973565 2077591 2610569 2826143 3078440 3379281 3388755 3759375 3802520 3957918 3990799 4044453 4069356 4383265 4597639 4809427 5094751 5643185"

local first_MS_list = "2678499 3699821"
local first_ON_list = "5134988 5271835 5726855"


foreach d of local first_ON_list {
	replace first_ON =1 if `d' == n_eid
}

foreach a of local first_MS_list {
	replace first_MS =1 if `a' == n_eid
}
foreach b of local identical_time {
	replace simult_MS_ON = 1 if `b' == n_eid
}

* a variable that indicates that a pariticpant has died, used to exclude from survival regression due to competing outcomes
generate died =.
replace died = 1 if ts_40000_0_0 !=. | ts_40000_1_0 !=.

* Generate follow_up_time using last HES update date
generate last_hes_update = date("15sep2020", "DMY")
format last_hes_update %td

generate follow_up_time = datediff(enrol_date, last_hes_update, "m")

***Calculate ON to MS (or end of f/u) time in people with ON followed by MS
generate ON_to_MS_time =.

replace ON_to_MS_time =  earliest_MS - earliest_ON if first_ON ==1 & died!=1

* Calculating f/u time if no MS present. earliest_ON is a positive value for incident cases, and a negative for prevalent cases (calculated as min(datediff(enrol_date, date_of_dis_record, "m") across all data sources) 

replace ON_to_MS_time = follow_up_time - earliest_ON if first_ON !=1 & first_MS !=1 & simult_MS_ON!=1 & died!=1

* replace the difference to 15 days (0.5 months) in people who have both diagnoses recorded less than a month apart, and thus it appears as 0 (because earliest_`dis' is calculated in months) 
replace ON_to_MS_time = 0.5 if ON_to_MS_time == 0 & first_ON ==1

generate ON_to_MS_years =. 
replace ON_to_MS_years = ON_to_MS_time / 12

generate age18to50 = 1 if aao_ON >= 240 & aao_ON <=600 & ON_any ==1
replace age18to50 = 0  if (aao_ON < 240 | aao_ON >600) & ON_any ==1

gen age_MS = aao_MS /12
gen age_ON = aao_ON /12

**** Using genetically defined unreated European ancestry individuals from a separate file, insert citatation **** 


merge 1:1 n_eid using "/slade/local/UKBB/phenotype_data/master/derived_data/Unrelated_EUR/500K_PLINK_pheno.dta", keepusing(pc1 pc2 pc3 pc4 pc5 centre ethnicity white insuff_ex) generate(ethn_merge)
drop if ethn_merge ==2


/*drop n_20009_*
drop n_20002_*
drop s_40001_*
drop s_40002_*
drop s_41202*
drop s_41204_0_*
drop fid 
drop n_2200* */
