#! /bin/bash

cd /slade/home/pl450/MS_GRS_overall_1412/direct_hla_scoring_0701

module load PLINK/2.00a2.3_x86_64

nice plink2 --bgen /slade/projects/Research_Project-MRC158833/UKBiobank/500K_Genetic_data/imputed_data/ukb_imp_chr6_v3.bgen \
		--sample /slade/projects/Research_Project-MRC158833/UKBiobank/500K_Genetic_data/imputed_data/ukb9072_imp_autosomes.sample \
		--score two_snps_HLA_26_08.txt 3 4 9 header cols=+scoresums list-variants \
		--out two_hla_snps \
