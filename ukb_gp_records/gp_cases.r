library(RMySQL)
library(dplyr)
library(tcltk)
lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)  

pwd <- .rs.askForPassword("Database Password:")


abs_path <- "/slade/home/pl450/MS_GRS_overall_1412/gp_records_on_ms"

setwd(abs_path)

file_list <- c("ms_thincodes.csv", "on_thincodes.csv", "aber_on_ukbcodes.csv")

for (file in file_list) {

con=dbConnect(MySQL(),dbname="UKB_GP_RECORDS",password=pwd, user='pl450',host="slade.ex.ac.uk")

path_to_file <- file.path(abs_path, file)

read_codes <- read.delim(path_to_file, sep = ",", quote = "'", header=F)
	
read_list <- paste(paste0("'",as.list(read_codes$V1),"'"),collapse = ",") 

query <-"SELECT * FROM UKB_GP_RECORDS.gp_clinical_230K_171019 WHERE READ_3 IN (%s) OR READ_2 IN (%s);"

format_query <- sprintf(query,read_list, read_list)

df = dbSendQuery(con, format_query) %>% fetch(rsa, n=-1)
	
write.table(df, file = gsub("codes.csv", "_cases.tsv", path_to_file), sep= "\t", quote=FALSE, row.names=FALSE) 

lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)

}
