
# Parse arguments
# set global variables from command line arguments
parseArgs <- function(args=commandArgs(trailingOnly=TRUE)) {
    if(!exists("DATA_FILE"))
        DATA_FILE <<- args[1]
    if(!exists("YEAR_START"))
        YEAR_START <<- as.integer(args[2])
    if(!exists("YEAR_END"))
        YEAR_END <<- as.integer(args[3])
    if(!exists("PLOT_FILE"))
        PLOT_FILE <<- args[4]

    stopifnot( file.exists(DATA_FILE) )
    stopifnot( is.integer(YEAR_START) )
    stopifnot( is.integer(YEAR_END) )
    stopifnot( is.character(PLOT_FILE) )
    }

### Data functions ###
readData <- function() { 
    DATA <<- read.csv( 
        file = DATA_FILE
        ,sep = "|"
        )

    # convert time to date
    DATA$ZEIT <<- as.POSIXct( DATA$ZEIT )
    
    # sort by time
    DATA <<- DATA[order(DATA$ZEIT),]

    cutData() # drop data outside time range
    }

cutData <- function() { 
    year <- as.integer(strftime(DATA$ZEIT,format="%Y"))
    inrange <- YEAR_START <= year & year <= YEAR_END
    DATA <<- DATA[inrange,] # only keep rows in range
    }

# utilities
makeUtilities <- function() { 
    THIS_YEAR <<- as.integer(strftime(Sys.time(),format="%Y")) # the actual year
    PLOT_YEARS <<- seq(YEAR_START,YEAR_END) # plotted years
    PLOT_YEARS_TEXT <<- 
        if(length(PLOT_YEARS) == 1) { # only one year
            if(PLOT_YEARS == THIS_YEAR) 
                paste("dieses Jahr")
            else 
                paste("in",PLOT_YEARS)
        } else { # multiple years
            paste("von",min(PLOT_YEARS),"bis",max(PLOT_YEARS))
        }

    EMERGENCY_KIND_COLORS <<- list(
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

    DAYS <<- c("Montag","Dienstag","Mittwoch","Donnerstag","Freitag",
        "Samstag","Sonntag")
    MONTHS <<- c("Januar","Februar","März","April","Mai","Juni","Juli",
        "August","September","Oktober","November","Dezember")
    MONTHS_SHORT <<- c("Jan","Feb","März","April","Mai","Juni",
        "Juli","Aug","Sep","Okt","Nov","Dez")

    SCHEDULED <<- grepl("termin",DATA$alarmierungsart,ignore.case=T)
    }

# execute makeUtilities first!
dropScheduled <- function () {
    # drop scheduled data
    DATA <<- DATA[!SCHEDULED,]
    # add asterisk to PLOT_YEARS_TEXT
    PLOT_YEARS_TEXT <<- 
        gsub(x=PLOT_YEARS_TEXT,pattern="(\\s*\\*)?$",replacement=" \\*")
}

FONTSIZE <<- 11

### Plot functions ###
# open plot device
openDevice <- function(...) { 
    # options( device = "png" ) # this somehow prevents Rplots.pdf creation...
    png(file=PLOT_FILE
            ,width=400
            ,height=300
            ,res=96
            ,pointsize=FONTSIZE
            ,bg=par("bg")
            ,...)
    }

# general plot settings
plotSettings <- function() { 
    OLD_PAR <<- par(no.readonly=T) # old parameters
    # font
    quartzFonts(plotfont=c(
       "Noto Sans","Noto Sans Bold","Noto Sans Italic","Noto Sans Bold Italic"))
    par( bg = "white" ) # white background
    par( cex = 1 )
    par( cex.main = 1.2 )
    par( cex.lab = 0.9 )
    par( cex.sub = 0.9 )
    par( cex.axis = 0.8 )
    par( ps = FONTSIZE )
    par( family = "plotfont" ) # font
    }

# plot the footer
plotFooter <- function() { 
    # signature
    mtext(side=1,line=par("mar")[1]-1,
                text="www.feuerwehr-aumuehle.de",
                adj=1, # right adjusted
                cex=par("cex.lab"),
                col="#333333"
    )
    # creation time
    # but only if current year is plotted somehow
    if(THIS_YEAR %in% PLOT_YEARS) {
        mtext(side=1,line=par("mar")[1]-1,
                    text=paste(
                        "Stand:",strftime(x=Sys.time(),format="%d.%m.%Y")),
                    adj=0, # linksbündig
                    cex=par("cex.lab"),
                    col="#333333"
            )
        }
    }

# close all PNG devices, thus write output file
closeDevice <- function() {
    for(dev in as.numeric(dev.list()[which(names(dev.list())=="png")])) {
        dev.off(dev) 
        }
    rm(dev)
    }


### statistical utilities ###
PRNGfromSample <- function(
        x,
        cdf=ecdf(x),
        xmin=min(x,na.rm=T),
        xmax=max(x,na.rm=T)
        ) {
    x_s <- c(xmin,sort(x),xmin)
    inv <- approxfun( x = cdf(x_s), y = x_s)
    prng <- function(n) inv(runif(n))
    return(prng)
    }

### Do it ###
init <- function() {
    parseArgs() # parse CMD arguments

    readData() # read data

    makeUtilities() # calculate utilities

    openDevice() # open device

    plotSettings() # plot settings
    }
