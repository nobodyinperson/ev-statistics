#!/usr/bin/env Rscript

# source function file
THIS_DIR <- dirname(sub(
 x = grep(x=commandArgs( trailingOnly = FALSE ),pattern="--file=",value=TRUE),
 pattern = "--file=", replacement = ""))
source(paste(THIS_DIR,"functions.R",sep="/"))

openDevice() # open device

plotSettings() # plot settings

EinsatzArtenHauptAlle = DATA$EINSATZART.HAUPT
EinsatzArtenHaupt = unique(EinsatzArtenHauptAlle)

EinsatzArtenHaeufigkeit <- sapply( 
    EinsatzArtenHaupt, function(x) length(which(EinsatzArtenHauptAlle==x)) )

EinsatzArtenHaeufigkeit <-
    data.frame(Art=EinsatzArtenHaupt,Anzahl=EinsatzArtenHaeufigkeit)

EMERGENCY_KIND_COLORSVector <- sapply(as.character(EinsatzArtenHaupt), 
    function(x){
    ifelse(is.null(EMERGENCY_KIND_COLORS[[x]]),NA,EMERGENCY_KIND_COLORS[[x]])
    })

# Einsatzhäufigkeit nach Monat und Art in Matrix speichern
# Zeile: Häufigkeit einer Einsatzart in jedem Monat
# Spalte: Aufteilung Einsatzarten in einem Monat
EinsaetzeMonateArten = 
    matrix(0,ncol=length(MONTHS_SHORT),nrow=length(EinsatzArtenHaupt))
for(art in EinsatzArtenHaupt){
    for(monat in MONTHS_SHORT) {
        EinsaetzeMonateArten[
            match(art,EinsatzArtenHaupt),match(monat,MONTHS_SHORT)] =
            length(which(match(monat,MONTHS_SHORT)==as.integer(
            strftime(x = DATA$ZEIT,format="%m"))&art==EinsatzArtenHauptAlle))
    }
}

# Barplot
par(mar=c(4,2,3,2)+0.1)
MonateBarplot = barplot(height=EinsaetzeMonateArten,
    names.arg=MONTHS_SHORT,
    col=EMERGENCY_KIND_COLORSVector,
    main=paste("Verteilung der Einsatzarten im Jahr\n",PLOT_YEARS_TEXT),
    #xlab="Monat",
    yaxt="n",
    ylim=c(0,max(apply(EinsaetzeMonateArten,2,sum),na.rm=T)*1.2),
    las=2
)

legend("topleft"
    ,legend="Farben wie in Einsatzarten-Grafik"
    ,bty="n"
    ,cex=par("cex.lab")
    )

plotFooter() # footer

closeDevice() # close device and write file
