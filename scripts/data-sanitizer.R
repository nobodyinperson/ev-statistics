#!/usr/bin/env Rscript

options( stringsAsFactors = FALSE )

# command line arguments
ARGS <- commandArgs(trailingOnly = TRUE)
INPUT <- ARGS[1]

# read data
DATA <- read.csv(INPUT,sep="|",quote="'")

#####################
### sanitize data ###
#####################
# drop unnecessary columns
DATA = DATA[,-grep("(bilder)|(mysteri)|(berichte)|(presse)|(video)",
    colnames(DATA),ignore.case = T)]

# get full time from date and time
DATA$ZEIT <- as.POSIXct(
    paste(DATA$datum,DATA$alarmzeit),format="%n%d.%n%B%n%Y%n%H:%M%n")

# sanitize duration
hours <- strtoi(sub(x = DATA$dauer, 
		pattern =  "^.*?(\\d+)\\s*stunde.*$", replacement = "\\1", 
		perl = TRUE, ignore.case = TRUE))
minutes <- strtoi(sub(x = DATA$dauer, 
		pattern =  "^.*?(\\d+)\\s*minute.*$", replacement = "\\1", 
		perl = TRUE, ignore.case = TRUE))
  hours[is.na(hours)&is.finite(minutes)] <- 0
minutes[is.na(minutes)&is.finite(hours)] <- 0
DATA$EINSATZDAUER.MINUTEN <- 60 * hours + minutes

# calculate total number of active members
DATA$MANNSCHAFT.GESAMT <- sapply(
    strsplit(x=as.character(DATA$mannschaftsstrke), split = "\\D+"),
    function(x)sum(as.numeric(x)))

# get overall topic
DATA$EINSATZART.HAUPT <- 
    gsub(x=DATA$art,pattern="^\\s*(\\w+)\\s*>.*$",replacement = "\\1")

# remove gallery from report
DATA$einsatzbericht <- gsub(
    x=DATA$einsatzbericht,pattern = "#gallery.*?\\*/",replacement = "")
	

# write output data
write.table( 
    x = DATA, # the data
    file = stdout(), # write to STDOUT
    quote = FALSE,
    sep = "|",
    eol = "\r\n",
    na = "",
    row.names = F
    )

