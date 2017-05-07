#!/usr/bin/env Rscript

### functions ###
concatenate.data.frames = function(x,y,fill=NA) {
	for(col in setdiff(colnames(y),colnames(x))) x[col] = fill
	for(col in setdiff(colnames(x),colnames(y))) y[col] = fill
	return(rbind(x,y))
}

options( stringsAsFactors = FALSE )

for (file in commandArgs(trailingOnly = TRUE)) { 
    CUR <- read.csv(file,sep="|",quote="'")
    if(exists("DATA"))
        DATA <- concatenate.data.frames(DATA,CUR)
    else
        DATA <- CUR
    }

write.table( 
    x = DATA, # the data
    file = stdout(), # write to STDOUT
    quote = FALSE,
    sep = "|",
    eol = "\r\n",
    na = "",
    row.names = F
    )
