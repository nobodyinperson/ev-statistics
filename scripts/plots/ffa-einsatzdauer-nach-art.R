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

EinsatzArtenHauptAlle = DATA$EINSATZART.HAUPT
EinsatzArtenHaupt = unique(EinsatzArtenHauptAlle)

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

EinsatzArtenDauer <- sapply( EinsatzArtenHaupt, 
    function(art) {
        mean(DATA$EINSATZDAUER.MINUTEN[which(EinsatzArtenHauptAlle==art)],
            na.rm = T)
        } )

EinsatzArtenFarbeCompVector <- 
    sapply(EinsatzArtenFarbeVector,
        function(color)do.call(rgb, as.list(1 - col2rgb(color) / 255)))

# Barplot
par(mar=c(2,1,3,1)+0.1)
EinsatzArtenDauerBarplot = barplot(
    height=EinsatzArtenDauer[rev(order(EinsatzArtenDauer))],
    names.arg=EinsatzArtenHaupt[rev(order(EinsatzArtenDauer))],
    col=EinsatzArtenFarbeVector[rev(order(EinsatzArtenDauer))],
    main=paste("Mittlere Einsatzdauer\nnach Einsatzart\n",PLOT_YEARS_TEXT),
    ylab="mittl. Einsatzdauer in Stunden",
    yaxt="n",
    xaxt="n",
    ylim=c(0,max(EinsatzArtenDauer,na.rm=T)*1.1),
    
)

legend(x="topright",legend = "in Minuten",bty='n'
    # ,cex=0.8
    )
text(x = EinsatzArtenDauerBarplot,
    y=EinsatzArtenDauer[rev(order(EinsatzArtenDauer))],
    labels = sprintf("%i",
        as.integer(EinsatzArtenDauer[rev(order(EinsatzArtenDauer))])),
    pos=3,offset=0.2
    # ,cex=0.7
    )


# Arten hinschreiben
text(x = EinsatzArtenDauerBarplot,
    y=EinsatzArtenDauer[rev(order(EinsatzArtenDauer))]/2,
    # 		 y=0,
    srt=90,
    font=2,
    adj=0.5,
    col=gray(apply(col2rgb(col = EinsatzArtenFarbeCompVector),2,
        function(x){ifelse(mean(x)>256/2,256,0)}
        )/256)[rev(order(EinsatzArtenDauer))],
    # cex=0.6,
    labels = EinsatzArtenHaupt[rev(order(EinsatzArtenDauer))]
    )

plotFooter() # footer

closeDevice() # close device and write file
