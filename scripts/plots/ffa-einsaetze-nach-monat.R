#!/usr/bin/env Rscript

# source function file
THIS_DIR <- dirname(sub(
 x = grep(x=commandArgs( trailingOnly = FALSE ),pattern="--file=",value=TRUE),
 pattern = "--file=", replacement = ""))
source(paste(THIS_DIR,"functions.R",sep="/"))

openDevice() # open device

plotSettings() # plot settings

# Einsatzzeiten aller vollen Jahre
JahreEinsaetzZeiten <-
    DATA$ZEIT[as.numeric(strftime(x = DATA$ZEIT,format = "%Y"))%in%PLOT_YEARS]
# Die MONTHS_SHORT dazu
JahreMonate = as.numeric(strftime(x = JahreEinsaetzZeiten,format = "%m"))
JahreEinsaetzZeiten<-NULL # Speicherplatz sparen

MonateColors <-
    colorRampPalette(
        c("gray","green4","yellow","brown","gray"))(length(MONTHS_SHORT))
# MonateAnzahl = c()
# for(monat in 1:12) { # Alle MONTHS_SHORT durchgehen
#     MonateAnzahl[monat] = 
# } ;rm(monat)
MonateAnzahl <- sapply( seq_along(MONTHS_SHORT), 
    function(monat) length(which(JahreMonate==monat)) )
MonateAnteil = MonateAnzahl / sum(MonateAnzahl)

# Barplot
par(mar=c(4,2,3,2)+0.1)
MonateBarplot = barplot(height=MonateAnteil,
    names.arg=MONTHS_SHORT,
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
    text(x = MonateBarplot,y=MonateAnteil
        ,cex = par("cex.axis")
        ,labels = MonateAnzahl,pos=3)
} else {
    text(x = MonateBarplot,
        y=MonateAnteil,
        labels = sprintf("%.1f",MonateAnzahl/length(PLOT_YEARS)),pos=3,
        cex=par("cex.axis"))
}

plotFooter() # footer

closeDevice() # close device and write file
