#!/usr/bin/env Rscript

# source function file
THIS_DIR <- dirname(sub(
 x = grep(x=commandArgs( trailingOnly = FALSE ),pattern="--file=",value=TRUE),
 pattern = "--file=", replacement = ""))
source(paste(THIS_DIR,"functions.R",sep="/"))

init() # initialise data and plot

library(graphics)

EinsatzArtenHauptAlle = DATA$EINSATZART.HAUPT
EinsatzArtenHaupt = unique(EinsatzArtenHauptAlle)

EMERGENCY_KIND_COLORSVector <- sapply(as.character(EinsatzArtenHaupt), 
            function(x){
            ifelse(is.null(EMERGENCY_KIND_COLORS[[x]]),
            NA,EMERGENCY_KIND_COLORS[[x]])
            })

EinsatzArtenDauer <- sapply( EinsatzArtenHaupt, 
    function(art) {
        mean(DATA$EINSATZDAUER.MINUTEN[which(EinsatzArtenHauptAlle==art)],
            na.rm = T)
        } )

EMERGENCY_KIND_COLORSCompVector <- 
    sapply(EMERGENCY_KIND_COLORSVector,
        function(color)do.call(rgb, as.list(1 - col2rgb(color) / 255)))

# Barplot
par(mar=c(1,1,3.5,1)+0.1)
ord <- rev(order(EinsatzArtenDauer))
EinsatzArtenDauerBarplot = barplot(
    height=EinsatzArtenDauer[ord],
    names.arg=EinsatzArtenHaupt[ord],
    col=EMERGENCY_KIND_COLORSVector[ord],
    main=paste("Durchschn. Einsatzdauer\nnach Einsatzart\n",PLOT_YEARS_TEXT),
    ylab="mittl. Einsatzdauer in Minuten",
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
    x=EinsatzArtenDauer[ord],
    labels = sprintf("%i", as.integer(EinsatzArtenDauer[ord]))
    ,pos=4
    ,font=2
    ,offset=0.5
    ,cex=par("cex.axis")
    )

name_width <- sapply(EinsatzArtenHaupt[ord],strwidth)
# text_x <- EinsatzArtenDauer[ord]/2 # inside by default
# text_x[EinsatzArtenDauer[ord]<name_width] <-
#     EinsatzArtenDauer[ord] + name_width/2
# Arten hinschreiben
for (i in seq_along(EinsatzArtenHaupt[ord])) {
    quot <- name_width[i] / EinsatzArtenDauer[ord][i]
    this.cex <- 
        if(quot > 1) par("cex.axis") / quot
        else         par("cex.axis")
    text(y = EinsatzArtenDauerBarplot[i],
        x=EinsatzArtenDauer[ord][i]/2,
        # srt=90,
        font=2,
        adj=0.5,
        col=gray(apply(col2rgb(col = EMERGENCY_KIND_COLORSCompVector),2,
            function(x){ifelse(mean(x)>256/2,256,0)}
            )/256)[ord][i],
        cex=this.cex,
        labels = EinsatzArtenHaupt[ord][i]
        )
    }

plotFooter() # footer

closeDevice() # close device and write file
