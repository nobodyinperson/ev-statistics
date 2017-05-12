#!/usr/bin/env Rscript

# source function file
THIS_DIR <- dirname(sub(
 x = grep(x=commandArgs( trailingOnly = FALSE ),pattern="--file=",value=TRUE),
 pattern = "--file=", replacement = ""))
source(paste(THIS_DIR,"functions.R",sep="/"))

init() # initialise data and plot

dropScheduled() # drop scheduled

# UhrzeitCT <-
#     as.POSIXct(strftime(x=DATA$ZEIT,format = "%H:%M:%S"),format="%H:%M:%S")
Hour <- as.integer(strftime(x = DATA$ZEIT, format = "%H"))
HourColorsSequence = sin(seq(f=0,t=pi,l=24))^1.8 # grayscale
HourColors = gray(HourColorsSequence) # Die Farbskala
# Grafikparameter
par(mar=c(3,2,3,2)+0.1)
# Histogramm
# Terminierte / abgesprochene Einsätze rausgenommen (z.B. Brandsicherheitswache)
hist(
    x = Hour,
    breaks=seq(f=0,t=24),
    right=F,
    main=paste("Einsatzhäufigkeit nach Uhrzeit\n",PLOT_YEARS_TEXT),
    xlab="",
    yaxt="n",
    xaxt="n",
    ylab="",
    col=HourColors
)
AllHours <- seq(f=0,t=24,by=2)
axis(side = 1
    ,line = -1
    ,at=AllHours
    ,labels = paste(AllHours,"00",sep=":")
    ,tick = FALSE
    )

plotFooter() # footer

closeDevice() # close device and write file
