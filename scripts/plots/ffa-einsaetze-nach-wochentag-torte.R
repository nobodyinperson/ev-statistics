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

# Geplante / terminierte Einsätze ausgenommen (z.B. Brandsicherheitswache)
WochentageEinsaetze <- strftime(
    x = DATA$ZEIT[!grepl("Termin",DATA$alarmierungsart)], format = "%u")
Wochentage <-
    c("Montag","Dienstag","Mittwoch","Donnerstag","Freitag","Samstag","Sonntag")
WochentageHaeufigkeit <-
    sapply( 1:7, function(tag) length(which(WochentageEinsaetze==tag)) )
WochentageHaeufigkeit = WochentageHaeufigkeit / length(WochentageEinsaetze)
WochentageColors = c(
    colorRampPalette(c("yellow","darkorange"))(5),
    colorRampPalette(c("darkgreen","green4"))(2))
WochentageColors[WochentageHaeufigkeit==max(WochentageHaeufigkeit)] = "red"

par(mar=c(0,0,4,0)) # Weniger Rand
pie(WochentageHaeufigkeit,
    labels = ifelse(
        WochentageHaeufigkeit>0,
        paste(Wochentage," (",sprintf("%.0f%%",WochentageHaeufigkeit*100),")",
            sep=""),NA),
    col = WochentageColors,
    init.angle=180,
    cex = 0.8,
    clockwise=T,
    main=paste("Einsatzhäufigkeit nach Wochentag *\n",PLOT_YEARS_TEXT),
)

plotFooter() # footer

closeDevice() # close device and write file