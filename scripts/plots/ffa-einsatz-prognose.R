#!/usr/bin/env Rscript

# DATA_FILE <- "data/all-data-sane.csv"
# YEAR_START <- as.integer(2011)
# YEAR_END   <- as.integer(2017)
# PLOT_FILE  <- "plots/ffa-einsatz-prognose.png"

# source function file
THIS_DIR <- dirname(sub(
 x = grep(x=commandArgs( trailingOnly = FALSE ),pattern="--file=",value=TRUE),
 pattern = "--file=", replacement = ""))
if(length(THIS_DIR)<1) THIS_DIR <- getSrcDirectory(function(x){x})
source(paste(THIS_DIR,"functions.R",sep="/"))

# calculate difference between emergencies
TIME <- as.integer(sort(as.numeric(DATA$ZEIT - min(DATA$ZEIT))[!SCHEDULED]))
TIME_DIFF <- as.integer(diff(TIME))
TIME_SINCE_LAST_EMERGENCY <- as.numeric(Sys.time())-as.numeric(max(DATA$ZEIT))

ENSEMBLE_SIZE <- 10000

ROW_NAMES <- paste("m",seq(ENSEMBLE_SIZE),sep="")
COL_NAMES <- paste("e",seq_along(TIME_DIFF),sep="")
# get ensemble of time differences
ENSEMBLE_DIFF <- t(sapply(seq(ENSEMBLE_SIZE),function(nr)sample(TIME_DIFF)))
colnames(ENSEMBLE_DIFF)<-COL_NAMES
rownames(ENSEMBLE_DIFF)<-ROW_NAMES

# quality check: histogram stays the same

# cumulate time differences
ENSEMBLE_TIME <- t(apply(ENSEMBLE_DIFF,1,cumsum))
stopifnot(all(ENSEMBLE_TIME[1,]==cumsum(ENSEMBLE_DIFF[1,]))) # quality check


SECONDS_PER_DAY <- 60 * 60 * 24
SECONDS_PER_WEEK <- SECONDS_PER_DAY * 7
SECONDS_PER_MONTH <- SECONDS_PER_WEEK * 4

probability <- function(timespan) { 
        low <- length(which(
                apply(ENSEMBLE_TIME,1,
                            function(x)any(x<=timespan))
                )) / ENSEMBLE_SIZE
        high <- length(which(
                apply(ENSEMBLE_TIME,1,
                            function(x)any(x-TIME_SINCE_LAST_EMERGENCY<=timespan))
                )) / ENSEMBLE_SIZE
        return( c(low=low,high=high))
}

round_to <- function(x,base=5) round(round(x/base)*base)

DAY_PROBABILITY <- round_to(probability(SECONDS_PER_DAY)*100,5)
# print(round_to(DAY_PROBABILITY*100,5))
WEEK_PROBABILITY <- round_to(probability(SECONDS_PER_WEEK)*100,5)
# print(round_to(WEEK_PROBABILITY*100,5))
MONTH_PROBABILITY <- round_to(probability(SECONDS_PER_MONTH)*100,5)
# print(round_to(MONTH_PROBABILITY*100,5))

par(mar=c(3,0,2,0))
plot(runif(1000),runif(1000)
		,col=gsub(x=heat.colors(1000),pattern="..$",replacement = "22")
	 	,pch=20
		,cex=4
    ,axes = F
    ,xlab="",ylab=""
    ,main="Einsatzwahrscheinlichkeit\nPROGNOSE"
		,bg="green"
    )
mtext(side=1,line=1
    ,text = paste("Daten",PLOT_YEARS_TEXT,"\n",
        "Annahme: Statistik bleibt gleich")
    ,cex = par("cex.sub")
    )

usr <- par("usr")
text(x=mean(usr[c(1,2)])
    ,y=usr[3]+0.8*diff(usr[c(3,4)])/3
    ,font=2
		,bg="white"
    ,labels = paste("nächste 24 Stunden: "
        ,DAY_PROBABILITY[1],"-",DAY_PROBABILITY[2],"%")
)
text(x=mean(usr[c(1,2)])
    ,y=usr[3]+1.5*diff(usr[c(3,4)])/3
    ,font=2
    ,labels = paste("nächste 7 Tage: "
        ,WEEK_PROBABILITY[1],"-",WEEK_PROBABILITY[2],"%")
)
text(x=mean(usr[c(1,2)])
    ,y=usr[3]+2.2*diff(usr[c(3,4)])/3
    ,font=2
    ,labels = paste("nächste 30 Tage: "
        ,MONTH_PROBABILITY[1],"-",MONTH_PROBABILITY[2],"%")
)

plotFooter() # footer

closeDevice() # close device and write file