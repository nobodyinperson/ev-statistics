#!/usr/bin/Rscript
# Aus der aktuellen Seite die Daten laden
library(XML)

#### Funktionen laden ####
cat("Funktionen einlesen...")
# source("/home/pi/FFA-Statistiken/Skripte/FFA-Daten-laden-Funktionen.R")
source(ifelse(system("whoami",intern=T)=="pi","/home/pi/FFA-Statistiken/Skripte/FFA-Daten-laden-Funktionen.R","Skripte/FFA-Daten-laden-Funktionen.R"))
cat("fertig!\n")
cat("\n")

#### Einstellungen ####
SETTINGS = list()
SETTINGS$EXPORT <- T  # Sollen die Daten exportiert werden?
SETTINGS$EXPORTFOLDER = ifelse(system("whoami",intern=T)=="pi","/var/www/FFA/Daten/","Daten/")
SETTINGS$EXPORTFILENAME <- ifelse(system("whoami",intern=T)=="pi","/var/www/FFA/Daten/Einsaetze.csv","Daten/Einsaetze.csv") # In welche Datei sollen die Daten exportiert werden?

#### Parameter ####
PARAM = list()
# Das ist die HomePage, auf der alle Links zu den Einsatz-Detailseiten sind

# ALTE SEITE
#PARAM$EinsaetzePageURL = "http://vu2080.web2.premium-webspace.net/wopre/alle-einsaetze/alle-einsaetze-2/" # Der Link zu der gesamten Einsatzlisten-Seite

# NEUE OFFIZIELLE SEITE
PARAM$EinsaetzePageURL = "http://www.feuerwehr-aumuehle.de/wopre/alle-einsaetze/alle-einsaetze-2/" # Der Link zu der gesamten Einsatzlisten-Seite

# LOKAL 
# PARAM$EinsaetzePageURL = "Source/alle.html" # Der Link zu der gesamten Einsatzlisten-Seite

# Das ist der XPath, der auf der HomePage alle Links zu den Detailseiten liefert 
PARAM$EinsaetzeTabellenDetailLinksXPath = "//table[@class='einsatzverwaltung-reportlist']//a/@href" # Der XPath zu den Detailseiten-Links-href Attributen
# Das ist der XPath, der die Headerfelder auf einer Detailseite findet (z.B. die fettgedruckten bzw. die Überschriften)
PARAM$DetailPageHeaderXPath  = "//div[@class='post-content']//strong/text()|//div[@class='post-content']//h3/text()"
# Das ist der XPath, der den (sinnvollen, einsatzbezogenen) Inhalt auf einer Detailseite findet (samt Headerelemente z.B.)
PARAM$DetailPageContentXPath = "//div[@class='post-content']//text()"

# Variablen erstellen, wenn noch nicht vorhanden
DATA = list()
LOOP = list()


#### Detailseiten-Links holen ####
cat("Aus der gesamten Einsatzliste die Links zu den Detailseiten raussuchen...\n")

# read only the links
# DATA$EinsaetzeDetailLinks <- XML::getHTMLLinks(
# 	doc = PARAM$EinsaetzePageUR	
# 	,xp = PARAM$EinsaetzeTabellenDetailLinksXPath
# )

# read all tables in to a list
DATA$EinsaetzeTabellen <- XML::readHTMLTable(
	doc=PARAM$EinsaetzePageURL # take the 
	,as.data.frame=T # return a list of Data frames
	,header=T # there is a header
	,elFun=function(node){ # run this function on every <td>  ... </td> cell
		link<-XML::getHTMLLinks(node); # get all linnks from this node
		if(length(link)>0){ # if you found any
			return(link) # return this link
		}else{ # else
			return(xmlValue(node)) # return the text
		}
	}
)

# name the tables based on the dates
# name the tables based on the dates
names(DATA$EinsaetzeTabellen) <- sapply(DATA$EinsaetzeTabellen,function(x){
	names = unique(strftime(as.Date(x$Datum,format="%d.%m.%Y"),format="%Y"))
		names <- names[-is.na(names)]
			})


# Jetzt sind alle Jahres-Tabellen in der Variable DATA$EinsaetzeTabellen
cat("--->","Aus",length(DATA$EinsaetzeTabellen),"Einsatztabellen alle",sum(sapply(DATA$EinsaetzeTabellen, function(x)length(rownames(x)))),"Links rausgesucht!\n")
cat("\n")


#### Alle Detailseiten durchgehen ####
cat("Aus jeder Einsatz-Detailseite die Informationen extrahieren...\n")

if(exists("EINSAETZE")) rm(EINSAETZE) # Sicherstellen, dass Variable nicht existiert!


# Alle Tabellen durchgehen
for(tabnr in seq_along(DATA$EinsaetzeTabellen)) {
	table = DATA$EinsaetzeTabellen[[tabnr]]
	year = names(DATA$EinsaetzeTabellen)[tabnr]
	cat("Jahr",year,":")
	filename = paste(SETTINGS$EXPORTFOLDER,"Einsaetze-",year,".csv",sep="")
	
	if(!file.exists(filename) | year == strftime(Sys.time(),format="%Y")) {
		
		
		# Links liegen in "Einsatzmeldung"
		for(url in table$Einsatzmeldung) { 
			cat("\n")
			cat("Url",match(url,table$Einsatzmeldung),"von",length(table$Einsatzmeldung),"\n")
			
			# aus dieser Detailseite einen Data frame erstellen
			LOOP$ContentDataFrame <- FFA.get.data.frame.from.url(
				url = url,
				xpathheader = PARAM$DetailPageHeaderXPath,
				xpathcontent = PARAM$DetailPageContentXPath)
			
			# Zusammenfügen
			if(!exists("EINSAETZE"))
				EINSAETZE = LOOP$ContentDataFrame
			else
				EINSAETZE = concatenate.data.frames(EINSAETZE,LOOP$ContentDataFrame)
			
		} 
		
		cat("\n")
		cat("Daten bereinigen...")
		# replace stupid non-breaking spaces with normal spaces
		for(name in colnames(EINSAETZE)){EINSAETZE[,name]<-gsub("\302\240"," ",as.character(EINSAETZE[,name]),perl=T)}
		EINSAETZE <- FFA.correct.EINSAETZE.data.frame(EINSAETZE)
		cat("fertig!\n")
		
		if(SETTINGS$EXPORT) {
			cat("In CSV-Datei exportieren...")
			write.table(EINSAETZE,file = filename,quote = F,sep = ";",row.names = F,col.names = T,fileEncoding = "utf8")
			cat("fertig!\n")
			cat("\n")
		}
		
		rm(EINSAETZE)
		
	} else {
		cat ("Datei '",filename,"' existiert bereits! Jahr wird übersprungen.\n")
	}
	
}

cat("\n")
cat("Informationen wurden aus allen Einsatz-Detailseiten extrahiert!\n")
cat("\n")
cat("Produziere eine gesamte Datei...\n")
if(exists("EINSAETZE")) rm(EINSAETZE)
for(file in Sys.glob(paste(SETTINGS$EXPORTFOLDER,"/","Einsaetze-[0-9][0-9][0-9][0-9].csv",sep=""))){cat(file,"\n");d<-read.csv2(file);if(!exists("EINSAETZE")){EINSAETZE<-d}else{EINSAETZE<-concatenate.data.frames(EINSAETZE,d)}}
write.table(EINSAETZE,file = paste(SETTINGS$EXPORTFOLDER,"Einsaetze-alle.csv",sep=""),quote = F,sep = ";",row.names = F,col.names = T,fileEncoding = "utf8")
cat("fertig!\n")

# Aufräumen
rm(DATA)
rm(LOOP)
