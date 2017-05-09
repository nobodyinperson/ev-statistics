#!/usr/bin/env Rscript

# source function file
THIS_DIR <- dirname(sub(
 x = grep(x=commandArgs( trailingOnly = FALSE ),pattern="--file=",value=TRUE),
 pattern = "--file=", replacement = ""))
source(paste(THIS_DIR,"functions.R",sep="/"))

openDevice() # open device

plotSettings() # plot settings

par(mar=c(3,1,4,1)+0.1) 

plot(y=rep(1,length(DATA$ZEIT))
    ,x = seq(
        from=as.POSIXct(paste(min(PLOT_YEARS),"-01-01",sep="")),
        to=as.POSIXct(paste(max(PLOT_YEARS)+1,"-01-01",sep="")),
        len=length(DATA$ZEIT)
        )
    ,type="n",yaxt="n",ylab="",
    ,main=paste("Einsatz-Barcode\n",PLOT_YEARS_TEXT)
    #xlab=ifelse(length(PLOT$Jahre)==1,"Monat","Zeit")
    ,xlab = ""
    ,panel.last=abline(v=DATA$ZEIT,xpd=F)
    ,bty = "n" # no box
    )

plotFooter() # footer

closeDevice() # close device and write file
