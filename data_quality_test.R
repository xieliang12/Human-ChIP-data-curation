#data quality check#
install.packages("xlsx")
library(xlsx)
sgd_features <- read.xlsx("Documents/data_curator/SGD-Features.xlsx", 
                          sheetName="ORFs left arm of chr11",
                          stringsAsFactors = FALSE)

#check the row number which do not have mandatory columns
rows_nomandatory <- c()
manda_columns <- c("Row","Feature.type", "Start.coordinate", "Stop.coordinate",
                   "Primary.SGDID", "Strand")
for (i in 1:length(manda_columns)) {
    rows_nomandatory <- c(rows_nomandatory, 
                          which(is.na(sgd_features[,manda_columns[i]])))
}
rows_nomandatory <- unique(rows_nomandatory)
sgd_features[rows_nomandatory,]$Row
##error: Row=114, the Primary SGDID column is missing.

##error: Row=17, the whole data row is separated into 13 columns instead of 12.
##the data points in Gene name, Start coordinate, Stop coordinate and
##Strand are mislocated and should be moved one column left horizontally. 
##the "chromosome 11" in Secondary SGDID should be removed. and the extra date 
##column before description column should be removed.
##error: Row=31, the date format in Sequence version date column is not yyyy-mm-dd format.
##error: Row=81, the data points in Feature name and Gene name switched position.
##error: Row=55, the Gene name column is wrong. There is a date format value in it.
##error: Row=95, the Gene name is not in pattern since it has 4 letters instead of 
##3 letters.


#copy sgd_features dataset to sgd_new and correct the errors in rows 17 and 81
sgd_new <- sgd_features
sgd_new[sgd_new$Row == 17,][, c(4, 7:8, 12)] <- 
    sgd_new[sgd_new$Row == 17,][,c(5, 8:9, 13)]
sgd_new[sgd_new$Row == 17,][, "Stop.coordinate"] <- 
    as.numeric(as.character(sgd_new[sgd_new$Row == 17,][,"Strand"]))
sgd_new[sgd_new$Row == 17,][, c(5,6,10,13)] <- NA

temp_value <- sgd_new[sgd_new$Row == 81,][,"Feature.name"]
sgd_new[sgd_new$Row == 81,][,c(4,5)] <- 
    c(sgd_new[sgd_new$Row == 81,][,5], temp_value)

#remove the last empty column for sgd_new
sgd_new <- sgd_new[, c(1:12)]

#add the new column called strand_new based on Feature name column
extract_strand <- function(x) substr(x, 7, 7)
sgd_new$Strand_new <- lapply(sgd_new[, "Feature.name"], extract_strand)
sgd_new$match <- ifelse(sgd_new$Strand == sgd_new$Strand_new, 1, 0)
sgd_new[which(sgd_new$match == 0),]
##error: Row=42, there are 4 leading spaces in Feature name column.
##error: Row=89, the Strand information from Feature name column is 
##not consistent with Strand column information.

sgd_new$region <- sgd_new$Stop.coordinate - sgd_new$Start.coordinate
sgd_new$direction <- ifelse((sgd_new$Strand == "W"), 1,
                            ifelse((sgd_new$Strand == "C"), -1, 0))
sgd_new[which(sgd_new$region*sgd_new$direction < 0),]

