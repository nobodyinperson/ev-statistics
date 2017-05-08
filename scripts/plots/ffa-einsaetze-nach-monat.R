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

# Einsatzzeiten aller vollen Jahre
JahreEinsaetzZeiten <-
    DATA$ZEIT[as.numeric(strftime(x = DATA$ZEIT,format = "%Y"))%in%PLOT_YEARS]
# Die Monate dazu
JahreMonate = as.numeric(strftime(x = JahreEinsaetzZeiten,format = "%m"))
JahreEinsaetzZeiten<-NULL # Speicherplatz sparen

Monate = c("Januar","Februar","März","April","Mai","Juni","Juli","August",
    "September","Oktober","November","Dezember")
Monate = c("Jan","Feb","März","April","Mai","Juni",
    "Juli","Aug","Sep","Okt","Nov","Dez")
MonateColors <-
    colorRampPalette(c("gray","green4","yellow","brown","gray"))(length(Monate))
# MonateAnzahl = c()
# for(monat in 1:12) { # Alle Monate durchgehen
#     MonateAnzahl[monat] = 
# } ;rm(monat)
MonateAnzahl <- sapply( seq_along(Monate), 
    function(monat) length(which(JahreMonate==monat)) )
MonateAnteil = MonateAnzahl / sum(MonateAnzahl)

# Barplot
par(mar=c(5,2,3,2)+0.1)
MonateBarplot = barplot(height=MonateAnteil,
    names.arg=Monate,
    col=MonateColors,
    main=paste(
        ifelse(length(PLOT_YEARS)==1,
        "Anzahl Einsätze nach Monat","mittl. Anzahl Einsätze pro Monat"),"\n",
        PLOT_YEARS_TEXT,sep=""),
    #xlab="Monat",
    yaxt="n",
    ylim=c(0,max(MonateAnteil)*1.2),
    las=2
)
# Anzahl hinschreiben
if(length(PLOT_YEARS)==1) {
    text(x = MonateBarplot,y=MonateAnteil,labels = MonateAnzahl,pos=3)
} else {
    text(x = MonateBarplot,
        y=MonateAnteil,
        labels = sprintf("%.1f",MonateAnzahl/length(PLOT_YEARS)),pos=3,cex=0.8)
}

plotFooter() # footer

closeDevice() # close device and write file
