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

Monate = c("Januar","Februar","März","April","Mai","Juni","Juli","August",
    "September","Oktober","November","Dezember")
Monate = c("Jan","Feb","März","April","Mai","Juni",
    "Juli","Aug","Sep","Okt","Nov","Dez")

EinsatzArtenHauptAlle = DATA$EINSATZART.HAUPT
EinsatzArtenHaupt = unique(EinsatzArtenHauptAlle)

EinsatzArtenHaeufigkeit <- sapply( 
    EinsatzArtenHaupt, function(x) length(which(EinsatzArtenHauptAlle==x)) )

EinsatzArtenHaeufigkeit <-
    data.frame(Art=EinsatzArtenHaupt,Anzahl=EinsatzArtenHaeufigkeit)
EinsatzArtenFarbe = list(
    "Feuer" = "#d82900",
    "Unwetterschäden" = "#00b615",
    "Bahnunfall" = "red",
    "Umweltschäden" = "#b84600",
    "Technische Hilfe" = "darkblue",
    "Verkehrsunfall" = "black",
    "Hilfeleistung" = "#0098d8",
    "Brandsicherheitswache" = "yellow",
    "Rettung" = "orange",
    "Sonstiges" = "white"
)

EinsatzArtenFarbeVector <- sapply(as.character(EinsatzArtenHaupt), function(x){
            ifelse(is.null(EinsatzArtenFarbe[[x]]),NA,EinsatzArtenFarbe[[x]])
            })

# Einsatzhäufigkeit nach Monat und Art in Matrix speichern
# Zeile: Häufigkeit einer Einsatzart in jedem Monat
# Spalte: Aufteilung Einsatzarten in einem Monat
EinsaetzeMonateArten = 
    matrix(0,ncol=length(Monate),nrow=length(EinsatzArtenHaupt))
for(art in EinsatzArtenHaupt){
    for(monat in Monate) {
        EinsaetzeMonateArten[match(art,EinsatzArtenHaupt),match(monat,Monate)] =
            length(which(match(monat,Monate)==as.integer(
            strftime(x = DATA$ZEIT,format="%m"))&art==EinsatzArtenHauptAlle))
    }
}

# Barplot
par(mar=c(4,2,3,2)+0.1)
MonateBarplot = barplot(height=EinsaetzeMonateArten,
    names.arg=Monate,
    col=EinsatzArtenFarbeVector,
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
