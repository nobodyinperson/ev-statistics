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

par(mar=c(4,2,3,2)+0.1) # Ränder anpassen
WochentageBarplot = barplot(height = WochentageHaeufigkeit * 100,
    names.arg = Wochentage,
    main=paste("Einsatzhäufigkeit nach Wochentag\n",PLOT_YEARS_TEXT),
    ylab="Anteil an allen Einsätzen [%]",
    col=WochentageColors,
    yaxt="n",
    ylim=c(0,max(WochentageHaeufigkeit*100)*1.2)
)
text(x = WochentageBarplot,y=WochentageHaeufigkeit*100,
         labels = sprintf("%i%%",as.integer(WochentageHaeufigkeit*100)),pos=3
         )

plotFooter() # footer

closeDevice() # close device and write file
