#!/usr/bin/env python3

import pandas as pd
import numpy as np

# Writing a dictionary of HLA:beta scores
allele_scores = {'DRB1_1501': np.log(3.92), 'A_201': np.log(0.67), 'DRB1_301': np.log(1.16), 'DRB1_1303': np.log(2.62),
                 'DRB1_801': np.log(1.55), 'B_4402': np.log(0.78), 'B_3801': np.log(0.48), 'B_5501': np.log(0.63),
                 'DQB1_302': np.log(1.30), 'DQB1_301': np.log(0.60), 'DQA1_101': np.log(0.65)}

# Reading the imputed hla allele file from UKBB, selecting only the columns specified in allele_scores
allele_df = pd.read_csv("~/imputed_data/ukb_hla_v2.txt",
delimiter="\t", header=0, usecols=allele_scores.keys())

# Importing n_eid for the imputed alleles
indices = pd.read_csv("~/ukb_hla_dosage_v2.indiv",
delimiter="\t", header=None, names=['n_eid', 'FID'])

# Ensure the lengths match
assert len(allele_df) == len(indices)

# Concatenate indices and allele dataframes
master_df = pd.concat([indices, allele_df], axis=1)

# The following is based on the 10-allele model from Moutsianas et al 2015. Here we calculate
# the score of 8 HLA alleles, and the additive score of 2 SNPs is added later

master_df["hla_int_score"] = 0

for i in range(len(master_df)):
  
    #Additive score DRB1*15:01
    if round(master_df.loc[i, 'DRB1_1501'], 1) >= 0.7:
master_df.loc[i, "hla_int_score"] += round(master_df.loc[i, 'DRB1_1501']) * allele_scores['DRB1_1501']

    # Additive effect of DQA1*01:01 in the presence of DRB1*15:01
    if round(master_df.loc[i, "DQA1_101"], 1) >= 0.7:
master_df.loc[i, "hla_int_score"] += round(master_df.loc[i, "DQA1_101"]) * allele_scores['DQA1_101']

    # Homozygote correction term for DRB1*15:01
    if round(master_df.loc[i, 'DRB1_1501']) == 2:
master_df.loc[i, "hla_int_score"] += np.log(0.54)

    # Additive score for A1*02:01
    if round(master_df.loc[i, 'A_201'], 1) >= 0.7:
master_df.loc[i, 'hla_int_score'] += round(master_df.loc[i, 'A_201']) * allele_scores['A_201']

# Homozygote correction term for A1*02:01
    if round(master_df.loc[i, 'A_201']) == 2:
master_df.loc[i, 'hla_int_score'] += np.log(1.26)

    # Additive effect of DRB1*13:03
    if round(master_df.loc[i, 'DRB1_1303'], 1) >= 0.7:
master_df.loc[i, 'hla_int_score'] += round(master_df.loc[i, 'DRB1_1303']) * allele_scores['DRB1_1303']

    # Homozygote correction term for DRB1*03:01
    if round(master_df.loc[i, 'DRB1_301']) == 2:
master_df.loc[i, 'hla_int_score'] += np.log(2.58)

    # Additive term for DRB1*08:01
    if round(master_df.loc[i, 'DRB1_801'], 1) >= 0.7:
master_df.loc[i, 'hla_int_score'] += round(master_df.loc[i, 'DRB1_801']) * allele_scores['DRB1_801']

    # Additive term for B*44:02
    if round(master_df.loc[i, 'B_4402'], 1) >= 0.7:
master_df.loc[i, 'hla_int_score'] += round(master_df.loc[i, 'B_4402']) * allele_scores['B_4402']

    # Additive term for B*38:01
    if round(master_df.loc[i, 'B_3801'], 1) >= 0.7:
master_df.loc[i, 'hla_int_score'] += round(master_df.loc[i, 'B_3801']) * allele_scores['B_3801']

# Rename column to eight_inter_hla, to which the scores from 2 SNPs in the HLA region will be added
master_df.rename({'hla_int_score':"eight_inter_hla"}, axis=1, inplace=True)

# Save the dataframe to a TSV file
master_df.to_csv('8_hla_inter_grs_0701.tsv', sep = '\t', header = True, index = False)
