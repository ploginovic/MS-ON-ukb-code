#! /bin/bash

module load PLINK/2.00a2.3_x86_64

cd /slade/home/pl450/MS_GRS_overall_1412/non_HLA_GRS

for i in {1..22}; do
	plink \ 
	--bgen /slade/projects/Research_Project-MRC158833/UKBiobank/500K_Genetic_data/imputed_data/ukb_imp_chr1_v3.bgen \
	--sample /slade/projects/Research_Project-MRC158833/UKBiobank/500K_Genetic_data/imputed_data/ukb9072_imp_autosomes.sample \ 
	--score imsgc_gwas_discovery_p.000001 3 4 8 header \
	--out nonhla_msgrs_chr${i}_22_01; done