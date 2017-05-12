#!/usr/bin/env Rscript

# source function file
THIS_DIR <- dirname(sub(
 x = grep(x=commandArgs( trailingOnly = FALSE ),pattern="--file=",value=TRUE),
 pattern = "--file=", replacement = ""))
source(paste(THIS_DIR,"functions.R",sep="/"))

init() # initialise data and plot

PIEPLOT_TOOSMALL_ANGLE = 0.02 # in radians

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

# Torte zeichnen
par(mar=c(0,0,2,0)) # Weniger Rand
EMERGENCY_KIND_COLORSnSortiert <-
    EMERGENCY_KIND_COLORSVector[order(EinsatzArtenHaeufigkeit$Anzahl)]
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
    col=EMERGENCY_KIND_COLORSnSortiert,
    radius=0.60,
    cex=par("cex.axis")
)

if(length(EinsatzArtenZuKleinIndex) > 0) {
    legend(x="topright",
        legend=paste(
            EinsatzArtenLabelsSortiert[EinsatzArtenZuKleinIndex],
            " (",EinsatzArtenHaeufigkeitenSortiert[EinsatzArtenZuKleinIndex],
            ")",sep=""),
        col=EMERGENCY_KIND_COLORSnSortiert[EinsatzArtenZuKleinIndex],
        border="black",
        bty="n",
        cex=par("cex.axis"),
        fill=EMERGENCY_KIND_COLORSnSortiert[EinsatzArtenZuKleinIndex]
    )
}

plotFooter() # footer

closeDevice() # close device and write file
