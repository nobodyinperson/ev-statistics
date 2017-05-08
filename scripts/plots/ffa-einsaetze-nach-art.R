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

PIEPLOT_TOOSMALL_ANGLE = 0.02 # in radians

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

# Torte zeichnen
par(mar=c(0,0,2,0)) # Weniger Rand
EinsatzArtenFarbenSortiert <-
    EinsatzArtenFarbeVector[order(EinsatzArtenHaeufigkeit$Anzahl)]
EinsatzArtenLabelsSortiert <-
    EinsatzArtenHaeufigkeit$Art[order(EinsatzArtenHaeufigkeit$Anzahl)]
EinsatzArtenHaeufigkeitenSortiert <-
    EinsatzArtenHaeufigkeit$Anzahl[order(EinsatzArtenHaeufigkeit$Anzahl)]
EinsatzArtenLabelsAussortiert <- EinsatzArtenLabelsSortiert
EinsatzArtenZuKleinIndex <-
    which(EinsatzArtenHaeufigkeitenSortiert / 
    sum(EinsatzArtenHaeufigkeitenSortiert)<PIEPLOT_TOOSMALL_ANGLE)
EinsatzArtenLabelsAussortiert[EinsatzArtenZuKleinIndex] = NA
EinsatzArtenLabelsAussortiertIndex = 
    setdiff(seq_along(EinsatzArtenLabelsAussortiert),EinsatzArtenZuKleinIndex)

pie(x=EinsatzArtenHaeufigkeitenSortiert,
    labels = ifelse(
        is.na(EinsatzArtenLabelsAussortiert), NA,
        paste(EinsatzArtenLabelsAussortiert," (",
            EinsatzArtenHaeufigkeitenSortiert,")",sep="")),
    border = "black",
    init.angle=180, # turned
    main=paste("Einsatzhäufigkeit nach Einsatzart\n",PLOT_YEARS_TEXT),
    col=EinsatzArtenFarbenSortiert,
    radius=0.60,
    cex=0.7
)

if(length(EinsatzArtenZuKleinIndex) > 0) {
    legend(x="topright",
        legend=paste(
            EinsatzArtenLabelsSortiert[EinsatzArtenZuKleinIndex],
            " (",EinsatzArtenHaeufigkeitenSortiert[EinsatzArtenZuKleinIndex],
            ")",sep=""),
        col=EinsatzArtenFarbenSortiert[EinsatzArtenZuKleinIndex],
        border="black",
        bty="n",
        cex=0.8,
        fill=EinsatzArtenFarbenSortiert[EinsatzArtenZuKleinIndex]
    )
}

plotFooter() # footer

closeDevice() # close device and write file
