#!/usr/bin/env Rscript

# source function file
THIS_DIR <- dirname(sub(
 x = grep(x=commandArgs( trailingOnly = FALSE ),pattern="--file=",value=TRUE),
 pattern = "--file=", replacement = ""))
source(paste(THIS_DIR,"functions.R",sep="/"))

readData() # read data

EMERGENCIES_PER_YEAR <- c()
for(year in PLOT_YEARS) { 
    EMERGENCIES_PER_YEAR[match(year,PLOT_YEARS)] <-
        length(which(strftime(DATA$ZEIT,format="%Y")==year))
    }

openDevice() # open device

plotSettings() # plot settings

par(mar=c(4,2,4,2)+0.1)

# barplot
BARPLOT_HEIGHTS = barplot(
    height=EMERGENCIES_PER_YEAR,
    names.arg=PLOT_YEARS,
    col=terrain.colors(length(PLOT_YEARS)),
    main=paste("Anzahl Einsätze pro Jahr\n",PLOT_YEARS_TEXT),
    xlab="",
    yaxt="n",
    ylim=c(0,max(EMERGENCIES_PER_YEAR)*1.2)
)
# write amount
text(
    x = BARPLOT_HEIGHTS,
    ,y = EMERGENCIES_PER_YEAR
    ,labels = EMERGENCIES_PER_YEAR
    ,pos = 3
    ,cex = par("cex.axis")
    )

plotFooter() # footer

closeDevice() # close device and write file
