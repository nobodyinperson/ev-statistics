#!/usr/bin/env Rscript

# source function file
THIS_DIR <- dirname(sub(
 x = grep(x=commandArgs( trailingOnly = FALSE ),pattern="--file=",value=TRUE),
 pattern = "--file=", replacement = ""))
source(paste(THIS_DIR,"functions.R",sep="/"))

library(graphics)

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
par(mar=c(1,1,3.5,1)+0.1)
EinsatzArtenDauerBarplot = barplot(
    height=EinsatzArtenDauer[rev(order(EinsatzArtenDauer))],
    names.arg=EinsatzArtenHaupt[rev(order(EinsatzArtenDauer))],
    col=EinsatzArtenFarbeVector[rev(order(EinsatzArtenDauer))],
    main=paste("Mittlere Einsatzdauer\nnach Einsatzart\n",PLOT_YEARS_TEXT),
    ylab="mittl. Einsatzdauer in Stunden",
    horiz = T,
    # space = 0.5,
    yaxt="n",
    xaxt="n",
    xlim=c(0,max(EinsatzArtenDauer,na.rm=T)*1.1),
    
)
# axisticks <- axis(side=1,line=-1,tick=F)
# abline(v=axisticks,lty=2,lwd=2,col="#00000022")

legend(x="topright"
    ,legend = "in Minuten"
    # ,bty='n'
    ,box.col = "white",
    ,cex = par("cex.lab")
    )
text(y = EinsatzArtenDauerBarplot,
    x=EinsatzArtenDauer[rev(order(EinsatzArtenDauer))],
    labels = sprintf("%i",
        as.integer(EinsatzArtenDauer[rev(order(EinsatzArtenDauer))]))
    ,pos=4
    ,offset=0.5
    ,cex=par("cex.axis")
    )

name_width <- sapply(EinsatzArtenHaupt[rev(order(EinsatzArtenDauer))],strwidth)
# text_x <- EinsatzArtenDauer[rev(order(EinsatzArtenDauer))]/2 # inside by default
# text_x[EinsatzArtenDauer[rev(order(EinsatzArtenDauer))]<name_width] <-
#     EinsatzArtenDauer[rev(order(EinsatzArtenDauer))] + name_width/2
# Arten hinschreiben
for (i in seq_along(EinsatzArtenHaupt[rev(order(EinsatzArtenDauer))])) {
    quot <- name_width[i] / EinsatzArtenDauer[rev(order(EinsatzArtenDauer))][i]
    this.cex <- 
        if(quot > 1) par("cex.axis") / quot
        else         par("cex.axis")
    text(y = EinsatzArtenDauerBarplot[i],
        x=EinsatzArtenDauer[rev(order(EinsatzArtenDauer))][i]/2,
        # srt=90,
        font=2,
        adj=0.5,
        col=gray(apply(col2rgb(col = EinsatzArtenFarbeCompVector),2,
            function(x){ifelse(mean(x)>256/2,256,0)}
            )/256)[rev(order(EinsatzArtenDauer))][i],
        cex=this.cex,
        labels = EinsatzArtenHaupt[rev(order(EinsatzArtenDauer))][i]
        )
    }

plotFooter() # footer

closeDevice() # close device and write file
