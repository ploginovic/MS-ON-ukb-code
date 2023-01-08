# MS-ON-ukb-code
## Model available at https://ploginovic.shinyapps.io/ms_grs_predict/
### This repository contains a scripts used to generate MS-GRS and assess it in the context of unidifferentiated Optic Neuritis in UKBB

HLA-GRS was created using ***direct_hla_interaction_score.ipynb*** and 2 SNPs scored in PLINK2 using plink_twoHLA_snps.sh. Interaction HLA GRS is based on a 10-allele model reported by Moutsianas et al (2015, supplement page 15)

non-HLA GRS was created using file ***nonhla_plink_2201.sh***

non-HLA and HLA-GRS were merged using ***demo_nonhla_merge_2201.r***, which also produced final .tsv file used in stata analysis later

phenotypic analysis was done in stata using ***on_ms_ukb_v2_1.do*** 

Figures and subsequent ROC and survival analysis were performed in python ***final_step_analysis.ipynb***

Moutsianas, L., Jostins, L., Beecham, A.H., Dilthey, A.T., Xifara, D.K., Ban, M., Shah, T.S., Patsopoulos, N.A., Alfredsson, L., Anderson, C.A. and Attfield, K.E., 2015. Class II HLA interactions modulate genetic risk for multiple sclerosis. Nature genetics, 47(10), p.1107.
