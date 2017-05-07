#!/usr/bin/env Rscript

options( stringsAsFactors = FALSE )

# command line arguments
ARGS <- commandArgs(trailingOnly = TRUE)
INPUT <- ARGS[1]

# read data
EINSAETZE <- read.csv(INPUT,sep="|",quote="'")

# convert time
EINSAETZE$ZEIT <- as.POSIXct(EINSAETZE$ZEIT)

years = sort(strtoi(na.omit(unique(as.integer(strftime(EINSAETZE$ZEIT,"%Y"))))))

cat("AVAILABLE_YEARS =",years,"\n")
