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

HourColorsSequence = sin(seq(f=0,t=pi,l=24))^1.8 # grayscale
HourColors = gray(HourColorsSequence) # Die Farbskala

# Stunden von 00 Uhr bis 24 Uhr als POSIXct
Hours = seq(f=as.POSIXct(x="00",format="%H"),
    t=as.POSIXct(x="00",format="%H")+60*60*24-1,by="hours")
# Auf Stunden reduzierte Einsätze
EinsaetzeHours = as.POSIXct(x=strftime(x=DATA$ZEIT,format="%H"),format="%H")
# Gemittelte Mannschaftsstärke nach Zeit
MannschaftproZeit = c()

# Terminierte / abgesprochene Einsätze rausgenommen (z.B. Brandsicherheitswache)
for(hour in Hours) {
    MannschaftproZeit = 
        c(MannschaftproZeit,
          mean(DATA$MANNSCHAFT.GESAMT[which(
          EinsaetzeHours==hour&!grepl("Termin",DATA$alarmierungsart))],
          na.rm = T))
    }

par(mar=c(3,2,3,2)+0.1)

# Barplot
MannschaftBarplot=barplot(MannschaftproZeit, # Werte
    names.arg = strftime(Hours,format="%H:00"), # X-Achse
    # las=2,
    # tcl=0.5, # Achsenzeichen
    main=paste("Mittlere Mannschaftsstärke im Einsatz nach Uhrzeit *\n",
        PLOT_YEARS_TEXT),
    cex.main=0.9,
    col=HourColors,
    xaxt="n",
    las=2,
    cex.axis=0.8
)
axis(1,tick=F,
    at=MannschaftBarplot,labels=paste(0:23,":00",sep=""),cex.axis=0.7,line=-1)

# Linien einzeichnen
abline(h=9,col="#eeeeeeaa",lwd=17)
text(x=mean(c(par("usr")[1],par("usr")[2])),
    y = 9,labels = "HLF Besatzung - 8 Kameraden",font=2)

plotFooter() # footer

closeDevice() # close device and write file