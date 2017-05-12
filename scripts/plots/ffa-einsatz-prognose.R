#!/usr/bin/env Rscript

DATA_FILE <- "data/all-data-sane.csv"
YEAR_START <- as.integer(2011)
YEAR_END   <- as.integer(2017)
PLOT_FILE  <- "plots/ffa-einsatz-prognose.png"

# source function file
THIS_DIR <- dirname(sub(
 x = grep(x=commandArgs( trailingOnly = FALSE ),pattern="--file=",value=TRUE),
 pattern = "--file=", replacement = ""))
if(length(THIS_DIR)<1) THIS_DIR <- getSrcDirectory(function(x){x})
source(paste(THIS_DIR,"functions.R",sep="/"))

init() # initialise data and plot

dropScheduled() # drop scheduled

# constants
SECONDS_PER_HOUR <- 60 * 60
SECONDS_PER_DAY <- SECONDS_PER_HOUR * 24
SECONDS_PER_WEEK <- SECONDS_PER_DAY * 7
SECONDS_PER_MONTH <- SECONDS_PER_WEEK * 4

TIME_DIFF_THRESHOLD <- SECONDS_PER_HOUR # time diff threshold to drop

# ensemble settings
ENSEMBLE_SIZE <- 1000 # number of members
# estimate forecast time/number of draws of each member
ENSEMBLE_MEMBER_LENGTH <- ceiling(SECONDS_PER_MONTH/mean(TIME_DIFF)*4)
# quantiles to check
QUANTILES <- seq(0,1,l=11)


# calculate difference between emergencies
TIME_DIFF <- abs(diff(as.integer(DATA$ZEIT)))
# drop too small time differences
TIME_DIFF <- TIME_DIFF[TIME_DIFF>TIME_DIFF_THRESHOLD]
TIME_SINCE_LAST_EMERGENCY <- as.integer(Sys.time())-as.integer(max(DATA$ZEIT))

TIME_MOY_PLUS_SIM <- MonthOfYearPlusSecondInMonth(DATA$ZEIT)
TIME_MOY_PLUS_SIM_QUANTILES <- quantile(TIME_MOY_PLUS_SIM,probs=QUANTILES)

# random number generator for time differences
prng <- PRNGfromSample(TIME_DIFF,xmin=0)
# wrapper to drop diffs lower than TIME_DIFF_THRESHOLD
TIME_DIFF_PRNG <- function(n) { 
    s <- prng(n)
    s[s<TIME_DIFF_THRESHOLD] <- TIME_DIFF_THRESHOLD
    return(s)
    }

# get ensemble of time differences
ENSEMBLE_DIFF <- t(sapply(seq(ENSEMBLE_SIZE),
                   function(nr)TIME_DIFF_PRNG(ENSEMBLE_MEMBER_LENGTH)))
colnames(ENSEMBLE_DIFF)<-paste("e",seq(ENSEMBLE_MEMBER_LENGTH),sep="")
rownames(ENSEMBLE_DIFF)<-paste("m",seq(ENSEMBLE_SIZE),sep="")

# cumulate time differences
ENSEMBLE_REL_TIME <- t(apply(ENSEMBLE_DIFF,1,cumsum))
stopifnot(all(ENSEMBLE_REL_TIME[1,]==cumsum(ENSEMBLE_DIFF[1,]))) # quality check

# add relative time to current time to get actual time
ENSEMBLE_TIME_MOY_PLUS_SIM <- t(apply(ENSEMBLE_REL_TIME,1,
					function(t)MonthOfYearPlusSecondInMonth(t,origin=Sys.time())))
# check how equal the members' moy_plus_sim is to original data
ENSEMBLE_TIME_MOY_PLUS_SIM_DIST_EQUALITY <- 
	apply(ENSEMBLE_TIME_MOY_PLUS_SIM,1,
	function(moy_plus_sim){
		cor(quantile(moy_plus_sim,probs=QUANTILES),TIME_MOY_PLUS_SIM_QUANTILES)})

# only keep data that is 'good enough'
good <- ENSEMBLE_TIME_MOY_PLUS_SIM_DIST_EQUALITY > 0.95
ENSEMBLE_REL_TIME_GOOD <- ENSEMBLE_REL_TIME[good,]

probability <- function(timespan) { 
        low <- length(which(
                apply(ENSEMBLE_REL_TIME_GOOD,1,
                      function(x)any(x<=timespan))
                )) / nrow(ENSEMBLE_REL_TIME_GOOD)
        high <- length(which(
                apply(ENSEMBLE_REL_TIME_GOOD,1,
                      function(x)any(x-TIME_SINCE_LAST_EMERGENCY<=timespan))
                )) / nrow(ENSEMBLE_REL_TIME_GOOD)
        return( c(low=low,high=high))
}

round_to <- function(x,base=5) round(round(x/base)*base)
# like round, but don't reach 100
round_percent <- function(x) sapply(round(x),function(y)min(y,99)) 

DAY_PROBABILITY <- round_percent(probability(SECONDS_PER_DAY)*100)
cat("day probability:\n")
print(DAY_PROBABILITY)
WEEK_PROBABILITY <- round_percent(probability(SECONDS_PER_WEEK)*100)
cat("week probability:\n")
print(WEEK_PROBABILITY)
MONTH_PROBABILITY <- round_percent(probability(SECONDS_PER_MONTH)*100)
cat("month probability:\n")
print(MONTH_PROBABILITY)

par(mar=c(4,0,3,0))
plot(runif(1000),runif(1000)
    ,col=gsub(x=heat.colors(1000),pattern="..$",replacement = "22")
    ,pch=20
    ,cex=4
    ,axes = F
    ,xlab="",ylab=""
    ,main="kleiner Spaß:\nEinsatzwahrscheinlichkeit PROGNOSE"
    )
mtext(side=1,line=1.8
    ,font=4
    ,text = paste("Annahme: Verteilung der Dauer\nzwischen zwei",
        "aufeinanderfolgenden Einsätzen\n",PLOT_YEARS_TEXT,"bleibt gleich")
    ,cex = par("cex.sub")
    )
usr <- par("usr")
text(x=mean(usr[c(1,2)])
    ,y=usr[3]+0.8*diff(usr[c(3,4)])/3
    ,font=2
    ,bg="white"
    ,labels = paste("nächste 24 Stunden: ",DAY_PROBABILITY[2],"%")
)
text(x=mean(usr[c(1,2)])
    ,y=usr[3]+1.5*diff(usr[c(3,4)])/3
    ,font=2
    ,labels = paste("nächste 7 Tage: ",WEEK_PROBABILITY[2],"%")
)
text(x=mean(usr[c(1,2)])
    ,y=usr[3]+2.2*diff(usr[c(3,4)])/3
    ,font=2
    ,labels = paste("nächste 4 Wochen: ",MONTH_PROBABILITY[2],"%")
)

plotFooter() # footer

closeDevice() # close device and write file
