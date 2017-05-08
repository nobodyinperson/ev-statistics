#!/usr/bin/env Rscript

# source function file
THIS_DIR <- dirname(sub(
 x = grep(x=commandArgs( trailingOnly = FALSE ),pattern="--file=",value=TRUE),
 pattern = "--file=", replacement = ""))
source(paste(THIS_DIR,"functions.R",sep="/"))

parseArgs() # parse CMD arguments

readData() # read data

openDevice() # open device

plotSettings() # plot settings

UhrzeitCT <-
    as.POSIXct(strftime(x=DATA$ZEIT,format = "%H:%M:%S"),format="%H:%M:%S")
HourColorsSequence = sin(seq(f=0,t=pi,l=24))^1.8 # grayscale
HourColors = gray(HourColorsSequence) # Die Farbskala
# Grafikparameter
par(mar=c(3,2,3,2)+0.1)
# Histogramm
# Terminierte / abgesprochene Einsätze rausgenommen (z.B. Brandsicherheitswache)
hist(UhrzeitCT[!grepl("Termin",DATA$alarmierungsart)],breaks="hour",right=F,
         main=paste("Einsatzhäufigkeit nach Uhrzeit *\n",PLOT_YEARS_TEXT),
         xlab="",
         yaxt="n",ylab="",
         cex.axis=0.8,
         col=HourColors
)

plotFooter() # footer

closeDevice() # close device and write file
