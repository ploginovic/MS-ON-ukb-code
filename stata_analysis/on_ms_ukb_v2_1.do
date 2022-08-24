/* This file is recreating stata phenotypic analysis in a more comprehensive way
		*/

clear 		
******* Part 1 ******* Primary Care records analysis
//run "/slade/home/pl450/MS_GRS_overall_1412/stata_analysis/do_create_gp_dta.do"

//run "/slade/home/pl450/MS_GRS_overall_1412/stata_analysis/dis_hesin_create_dta.do"


******* Part 2 ******* Loading raw phenotype, first occurence, hes and gp records

clear 
set maxvar 64000 

* importing final .tsv file containing calculated GRS
import delimited "/slade/home/pl450/MS_GRS_overall_1412/summedchr_nonhla_msgrs_p000001.tsv"

* The following block uses raw phenotype data, containing self-reported diseases, icd10 diagnoses and many covariates, which are described in a separate file 
merge m:1 n_eid using "/slade/local/UKBB/phenotype_data/master/main_data/raw_data_2019.dta", keepusing(n_eid ts_53_0_0 n_52_0_0 n_31_0_0 n_34_0_0 n_189_0_0 n_22011_0_0 n_22012_0_0 n_21001_0_0 n_20002_* n_20009_* n_21000_0_0 n_22001_0_0 n_20116_* s_40001_* s_40002_* ts_40000_* s_41204* n_22009_0_1-n_22009_0_8 n_22005_0_0 n_22004_0_0 n_22006_0_0 n_22010_0_0 n_100021_* n_3436_* n_2867_*  n_1787_* n_1647_*)

keep if _merge ==3 
drop _merge 

* Adding first occurence data, which is supposed to capture all sources of diagnoses
merge 1:1 n_eid using "/slade/local/UKBB/phenotype_data/master/main_data/ukb_first_occurrences.dta", keepusing(n_eid n_131197_0_0 ts_131196_0_0 /* ON data-fields */ n_131043_0_0 ts_131042_0_0 /*MS*/) generate(first_occ_merge)

drop if first_occ_merge ==2
drop first_occ_merge

* Adding Mike's supplied list of ON patients from the GP records
merge m:1 n_eid using "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/on_diag_gp.dta", generate(on_gp_merge)
drop if on_gp_merge ==2

merge 1:1 n_eid using "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/ms_gp_only.dta", generate(ms_gp_merge)
drop if ms_gp_merge ==2

merge 1:1 n_eid using "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms/aber_on_to_remove.dta", generate(aber_gp_merge)
drop if aber_gp_merge ==2

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

rename n_20116_1_0 smoking_status_1
rename n_20116_2_0 smoking_status_2

rename n_1647_0_0 country_of_birth

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
sort n_22011_0_0, stable
by n_22011_0_0: generate order_kin= _n
drop if order_kin >= 2 & n_22012_0_0 > 0.0844 & n_22011_0_0!=.
drop order_kin 


* removing participants who have withdrawn from the UKBB 
run "/slade/local/UKBB/phenotype_data/scripts/do_files/withdrawn_participants.do"
drop if withdrawn ==1

** Calculating dummy DOB which will be used in date analysis

gen DOB = mdy(MOB, 15, YOB)
format DOB %td

generate age_in_years = datediff(DOB, enrol_date, "y")
generate age_in_months = datediff(DOB, enrol_date, "m")

generate enrol_age = datediff(DOB, enrol_date, "m")
generate enrol_age_years = datediff(DOB, enrol_date, "y")


******* Part 3: analysing imported data for diagnoses and dates

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
	replace gp_flag_`dis'_prev= gp_flag_`dis' if event_date_`dis' <= enrol_date & enrol_date !=. & event_date_`dis'!=. & event_date_`dis' > DOB

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

	generate three_source_`dis' = .
	replace three_source_`dis' =1 if gp_flag_`dis' ==1 | sr_flag_`dis' ==1 | hes_flag_`dis' ==1
	replace three_source_`dis' = 0 if three_source_`dis' !=1
	replace fo_flag_`dis' =0 if fo_flag_`dis' !=1

}
* Removing one case with MS self reported at 0.5 years 
drop if aao_MS < 12*15

*Removing one participant with missing diagnosis date 
drop if MS_any == 0 & (fo_flag_MS ==1 | three_source_MS ==1)

*Doing the same for ON, though this does not result in exlcusion
drop if ON_any==0 & (fo_flag_ON ==1 | three_source_ON==1)

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

gen mson_pres =. 
replace mson_pres =1 if first_MS ==1 | simult_MS_ON ==1

generate undif_ON =.
replace undif_ON =1 if ON_group == "ON only" | first_ON ==1

* a variable that indicates that a pariticpant has died, used to exclude from survival regression due to competing outcomes
generate died =.
replace died = 1 if ts_40000_0_0 !=. | ts_40000_1_0 !=.

* Generate follow_up_time using last HES update date
generate last_hes_update = date("15sep2020", "DMY")
format last_hes_update %td

generate follow_up_time = datediff(enrol_date, last_hes_update, "m")
generate death_time = datediff(enrol_dat, ts_40000_0_0, "m")

***Calculate ON to MS (or end of f/u) time in people with ON followed by MS
generate ON_to_MS_time =.

replace ON_to_MS_time =  earliest_MS - earliest_ON if first_ON ==1 & died!=1

* Calculating f/u time if no MS present. earliest_ON is a positive value for incident cases, and a negative for prevalent cases (calculated as min(datediff(enrol_date, date_of_dis_record, "m") across all data sources) 
replace ON_to_MS_time = follow_up_time - earliest_ON if first_ON !=1 & first_MS !=1 & simult_MS_ON!=1 & died!=1

*if died==1
replace ON_to_MS_time = death_time - earliest_ON if undif_ON ==1 & died ==1

* replace the difference to 15 days (0.5 months) in people who have both diagnoses recorded less than a month apart, and thus it appears as 0 (because earliest_`dis' is calculated in months) 
replace ON_to_MS_time = 0.5 if ON_to_MS_time == 0 & first_ON ==1

generate ON_to_MS_years =. 
replace ON_to_MS_years = ON_to_MS_time / 12

generate age18to50 = 1 if aao_ON >= 240 & aao_ON <=600 & ON_any ==1
replace age18to50 = 0  if (aao_ON < 240 | aao_ON >600) & ON_any ==1

gen age_MS = aao_MS /12
gen age_ON = aao_ON /12

generate age_MS_norm = (age_MS - 44.51579)/12.385863

gen weird_fu = .
replace weird_fu  =  death_time  - earliest_ON if died==1
replace weird_fu = follow_up_time - earliest_ON if died !=1
replace weird_fu = weird_fu /12

**** Using genetically defined unreated European ancestry individuals from a separate file, insert citatation **** 

merge 1:1 n_eid using "/slade/local/UKBB/phenotype_data/master/derived_data/Unrelated_EUR/500K_PLINK_pheno.dta", keepusing(pc1 pc2 pc3 pc4 pc5 centre ethnicity white insuff_ex) generate(ethn_merge)
drop if ethn_merge ==2

merge 1:1 n_eid using "/slade/projects/UKBB/phenotype_data/master/main_data/biomarkers_2019.dta", keepusing(n_3089*)

generate ever_smoked =.
replace ever_smoked =0 if smoking_status == 0 | smoking_status_1 ==0 | smoking_status_2==0 
replace ever_smoked =1 if smoking_status == 1 | smoking_status ==2 | smoking_status_1 ==1 | smoking_status_1==2 | smoking_status_2==1 | smoking_status_2==2 
replace ever_smoked =-3 if smoking_status ==-3 | smoking_status_1==-3 | smoking_status_2==-3 & (ever_smoked !=1 | ever_smoked!=2)

generate smoked_before_20  = .
foreach v of varlist n_3436_* { 
	replace smoked_before_20 = 1 if `v' < 20
}

foreach x of varlist n_2867_* {
	replace smoked_before_20 =1 if `x' < 20 
}

foreach v of varlist n_3436_* { 
	replace smoked_before_20 = 0 if `v' >= 20 & `v'!=. & smoked_before_20 !=1
}

foreach x of varlist n_2867_* {
	replace smoked_before_20 =0 if `x' >= 20 & `x'!=. & smoked_before_20 !=1 
}

replace smoked_before_20 = -3 if ever_smoked == -3
replace smoked_before_20 = 0 if ever_smoked ==0 & smoked_before_20!=1
replace smoked_before_20 = -3 if smoked_before_20==.

replace country_of_birth = n_1647_1_0 if country_of_birth ==. | (country_of_birth ==-3 & n_1647_1_0!=-3 & n_1647_1_0!=.)
replace country_of_birth = n_1647_2_0 if country_of_birth ==. | (country_of_birth ==-3 & n_1647_2_0!=-3 & n_1647_2_0!=.)
replace country_of_birth = 6 if country_of_birth ==. | country_of_birth==-3 | country_of_birth==-1

//Vitamin D levels. Based on Lin, L. Y., Smeeth, L., Langan, S., & Warren-Gash, C. (2021). Distribution of vitamin D status in the UK: a cross-sectional analysis of UK Biobank. BMJ open, 11(1), e038503.

gen vitd_level =. 

label define vitD 0 "sufficient" 1 "insufficient" 2 "defficient" 4 "missing"
label variable vitd_level vitD

replace vitd_level  =0 if n_30890_0_0 >= 50 & n_30890_0_0 !=.
replace vitd_level = 1 if n_30890_0_0 < 50  & n_30890_0_0 >=25
replace vitd_level = 2 if n_30890_0_0 < 25 & n_30890_0_0 !=.
replace vitd_level  =0 if n_30890_1_0 >= 50 & n_30890_1_0 !=. & vitd_level ==.
replace vitd_level = 1 if n_30890_1_0 < 50  & n_30890_1_0 >=25 & vitd_level ==.
replace vitd_level = 2 if n_30890_1_0 < 25 & n_30890_1_0 !=. & vitd_level ==.

replace vitd_level =0 if n_30896_0_0 ==5
replace vitd_level =2 if n_30896_0_0 ==4
replace vitd_level =0 if n_30896_1_0 ==5
replace vitd_level =2 if n_30896_1_0 ==4

replace vitd_level =4 if vitd_level ==.

//TDI Quintiles: Based on UK Data Service 2011 UK Townsend Deprivation Scores - Townsend Deprivation Scores Report (p15). available at https://statistics.ukdataservice.ac.uk/dataset/2011-uk-townsend-deprivation-scores/resource/f500b512-2f49-4e6f-8403-9417b9133f6

gen tdi_cat = .
replace tdi_cat = 1 if TDI <=-3.0900 & TDI!=.
replace tdi_cat = 2 if TDI <=-1.6852  & tdi_cat !=1 & TDI!=.
replace tdi_cat = 3 if TDI <=0.1709  & tdi_cat ==. & TDI!=.
replace tdi_cat =4 if TDI <=2.8689 & tdi_cat==. & TDI!=.
replace tdi_cat =5 if TDI <=13.5881 & tdi_cat==. & TDI!=.
replace tdi_cat = 6 if tdi_cat ==.


local fifty_ways_to_die = "C349 I219 C509 C259 I251 I259 C61 C159 C719 C189 C56 C64 J841 C19 C80 C221 C679 C169 G122 I64 C20 C900 C459 C439 C920 J449 J440 C800 F03 I619 J189 C859 C260 I802 I609 C220 G20 C541 G309 C809 I710 J180 X700 R99 J441 I269 C187 K709 C180 I639"

gen common_primary = .


	foreach i of local fifty_ways_to_die {
		display "Processing `i'"
		replace common_primary = 1 if regexm(s_40001_0_0,"^`i'.*")==1 
	}

/*drop n_20009_*
drop n_20002_*
drop s_40001_*
drop s_40002_*
drop fid 
drop n_2200*
drop s_41204_0_*
drop n_100021_*
drop ts_40000_*
drop n_100021_*
drop hes_flag_*
drop fo_flag_*
drop gp_flag_*
drop inc_time_* 
drop prev_time_*
drop age_sr*
drop age_fo*
drop age_hes*
drop read_2*
drop read_3* */

/*list s_40001_0_0 s_40002_0_0  s_40002_0_1 s_40002_0_2 s_40002_0_3 s_40002_0_4 s_40002_0_5 if undif_ON ==1 & died ==1
list n_eid DOB age_ON hes_flag_ON n_131197_0_0 sr_flag_ON fo_flag_ON age_fo_ON_months gp_flag_ON if fo_flag_ON ==1 & gp_flag_ON!=1 & sr_flag_ON!=1 & hes_flag_ON!=1 

list MS_any fo_flag_MS hes_flag_MS ON_any gp_flag_MS sr_flag_MS if fo_flag_MS==1 & hes_flag_MS!=1 & gp_flag_MS!=1 & sr_flag_MS!=1 */


//export delimited using "/slade/home/pl450/ON_UKBB/1802_python_analysis/on_ms_genpop_2502.tsv", delimiter(tab) replace


