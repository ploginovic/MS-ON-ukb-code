#! /bin/bash

cd /slade/home/pl450/MS_GRS_overall_1412/non_HLA_GRS/imsgc_disc_qc


# removing SNPs with duplicated rsid
cat imsgc_gwas_discovery_p.000001 |\
awk '{seen[$3]++; if(seen[$3]==1){ print}}' > imsgc_gwas_discovery_p.000001_nodup


# Removing palindromic variants
cat imsgc_gwas_discovery_p.000001_nodup |awk '!( ($4=="A" && $5=="T") || \
        ($4=="T" && $5=="A") || \
        ($4=="G" && $5=="C") || \
        ($4=="C" && $5=="G")) {print}'  > imsgc_gwas_discovery_p.000001_nopalindromes


#Removing variants without rs
cat imsgc_gwas_discovery_p.000001_nopalindromes | grep rs > imsgc_gwas_discovery_p.000001_qced


# clean-up unnecessary files 
rm imsgc_gwas_discovery_p.000001
rm imsgc_gwas_discovery_p.000001_nodup
rm imsgc_gwas_discovery_p.000001_nopalindromes

mv imsgc_gwas_discovery_p.000001_qced /slade/home/pl450/MS_GRS_overall_1412/non_HLA_GRS/
