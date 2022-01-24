
# Merging non-HLA calculated using nonhla_plink_2201.sh GRS across 22 chromosomes

file_path <- "/slade/home/pl450/MS_GRS_overall_1412/non_HLA_GRS/nonhla_msgrs_chrN_22_01.sscore"

for (i in 1:22){

	exact_file_name <- gsub("N", as.character(i), file_path)
	using_data <- read.delim(exact_file_name, header = TRUE, sep = "\t")

	if (i==1){
		master_data <- using_data
	}
	if (i>1){
		stopifnot(master_data$IID==using_data$IID)
		master_data$SCORE1_SUM <- master_data$SCORE1_SUM + using_data$SCORE1_SUM
		master_data$NMISS_ALLELE_CT <- master_data$NMISS_ALLELE_CT + using_data$NMISS_ALLELE_CT
		}
	 
}

#stopifnot(master_data$NMISS_ALLELE_CT != 616)

#renaming and removing columns 

drops <- c("X.FID", "NMISS_ALLELE_CT", "NAMED_ALLELE_DOSAGE_SUM", "SCORE1_AVG")
master_data <- master_data[, !(names(master_data)%in%drops)]

names(master_data)[names(master_data)=="IID"] = "n_eid"
names(master_data)[names(master_data)=="SCORE1_SUM"] = "expanded_nonhla_grs"

non_hla_data <- master_data


#Merging HLA interaction score from direct_hla_interaction_score.ipynb with 2 HLA SNPs scored separately using PLINK2 

hla_data <- read.delim("/slade/home/pl450/MS_GRS_overall_1412/direct_hla_scoring_0701/8_hla_inter_grs_0701.tsv", sep="\t", header=T)

snp_hla_data <- read.delim("/slade/home/pl450/MS_GRS_overall_1412/direct_hla_scoring_0701/two_hla_snps.sscore", sep="\t", header=T)

snp_drops <- c("X.FID", "NMISS_ALLELE_CT", "NAMED_ALLELE_DOSAGE_SUM", "SCORE1_AVG")
snp_hla_data <- snp_hla_data[ , !(names(snp_hla_data)%in%snp_drops)]

#Renaming columns

names(snp_hla_data)[names(snp_hla_data) == "IID"] = 'n_eid'
names(snp_hla_data)[names(snp_hla_data) == "SCORE1_SUM"] = 'two_hla_snp'
names(hla_data)[names(hla_data) == "X10_hla_grs"] = "eight_inter_hla"

master_df <- merge(hla_data, snp_hla_data, by="n_eid")

#merging non_HLA GRS with hla_GRS

master_df <- merge(master_df, non_hla_data, by="n_eid")


#Summing MS-GRS Components to produce the final MS-GRS (full_expanded)

master_df$ten_full_hla <- master_df$eight_inter_hla + master_df$two_hla_snp
master_df$full_expanded <- master_df$ten_full_hla + master_df$expanded_nonhla_grs


write.table(master_data,"/slade/home/pl450/MS_GRS_overall_1412/summedchr_nonhla_msgrs_p000001”, sep = "\t", quote = FALSE, col.names = FALSE, row.names = FALSE)