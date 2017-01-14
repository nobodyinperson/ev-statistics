#!/usr/bin/Rscript

# Aus der gegebenen URL alle Detailseiten-Links raussuchen
# Der xpath zu den Links im Dokument der url ist xpathtolinks
# UNTESTED: url müsste eigentlich auch ein HTML-Quelltext als character oder ein bereits geparstes XML Dokument sein können...
FFA.get.links.from.url <- function(url,xpathtolinks,quiet=F) {
	# Funktionen einlesen
	#source("/home/pi/FFA-Statistiken/Skripte/FFA-Statistiken-Funktionen.R")
	source(ifelse(system("whoami",intern=T)=="pi","/home/pi/FFA-Statistiken/Skripte/FFA-Statistiken-Funktionen.R","Skripte/FFA-Statistiken-Funktionen.R"))
	
	# Detailseiten-Links holen #
	if(!quiet) cat("Suche Links raus...\n")
	# Aus der gesamten Einsatzliste die Links zu den Detailseiten raussuchen
	# Hier stehen zunächst alle Attribute aller <a href="..." rel="..." ...>Baum droht zu fallen...</a> - Links drin
	# Uns interessieren aber nur die "href"-Attribute, das kommt danach!
	links <- FFA.XPath.from.HTML(url,xpath = xpathtolinks,quiet=quiet, xmlAttrs)
	links <- as.vector(links[names(links)=="href"]) # Nur die HREF-Attribute
	# Jetzt sind alle Links zu den Detailseiten in der Variable DATA$EinsaetzeDetailLinks
	if(!quiet) cat("--->",length(links),"Links rausgesucht!\n")
	return(links) # Links zurückgeben
}


# Aus der gegebenen URL einen data.frame() dem einen Einsatz auf dieser Seite erstellen
# Annahme: Die Informationen stehen auf der Seite nicht in Tabellenform, sondern in der Struktur HEADER...TEXT....HEADER...TEXT.....
# Wird ein Header gefunden, wird so lange Text in diese Headerspalte eingelesen, bis der nächste Header gefunden wird
# Der xpath zu den Headerelementen ist xpathheader
# Der xpath zu gesamtem Inhalt (Header mit zugehörigem Text) ist xpathcontent
# UNTESTED: url müsste eigentlich auch ein HTML-Quelltext als character oder ein bereits geparstes XML Dokument sein können...
FFA.get.data.frame.from.url = function(url,xpathheader,xpathcontent="/*",quiet=F) {
	# Funktionen einlesen
	#source("/home/pi/FFA-Statistiken/Skripte/FFA-Statistiken-Funktionen.R")
	source(ifelse(system("whoami",intern=T)=="pi","/home/pi/FFA-Statistiken/Skripte/FFA-Statistiken-Funktionen.R","Skripte/FFA-Statistiken-Funktionen.R"))
	
	# Variablen erstellen, wenn noch nicht vorhanden
	DATA = list()
	
	DATA$Url = url # Die Url
	DATA$Source = FFA.XPath.from.HTML(DATA$Url,quiet=quiet) # Der geparste XMLTree der Detailseite
	
	# Jetzt den 'Header' aus dem Einsatzbeitrag bestimmen. Die Einsatzseiten sind jetzt ja keine Tabelle mehr, sondern die
	# Elemente in Fettschrift sind die Felder... 
	# Die Überschrift 'Einsatzbericht' im <h3>-Feld wird auch mitgenommen
	if(!quiet) cat("---> Informationen auslesen...")
	DATA$Head = FFA.XPath.from.HTML(DATA$Source,xpath=xpathheader,quiet=quiet,xmlValue)
	DATA$Head = gsub(x=as.character(DATA$Head),pattern="^\\s+|:?\\s*$",replacement = "") # Whitespaces an Anfang und Ende entfernen
	DATA$Head = DATA$Head[DATA$Head!=""] # Leerzellen entfernen
	
	DATA$HeadAndContent = FFA.XPath.from.HTML(DATA$Source,xpath=xpathcontent,quiet=quiet,xmlValue)
	DATA$HeadAndContent = gsub(x=as.character(DATA$HeadAndContent),pattern="^\\s+|:?\\s*$",replacement = "") # Whitespaces an Anfang und Ende entfernen
	DATA$HeadAndContent = DATA$HeadAndContent[DATA$HeadAndContent!=""] # Leerzellen entfernen
	
	DATA$ContentSorted = rep("",length(DATA$Head)) # Leere Vorlage für den Inhalt
	for(Element in DATA$HeadAndContent) { # Gehe alle Header & Elemente durch
		if(Element %in% DATA$Head) DATA$HeadAkt = Element
		else DATA$ContentSorted[match(DATA$HeadAkt,DATA$Head)] = paste(DATA$ContentSorted[match(DATA$HeadAkt,DATA$Head)],Element,sep="")
	}
	if(!quiet) cat("fertig!\n")
	
	if(!quiet) cat("---> Informationen zusammenfügen...")
	DATA$ContentDataFrame = data.frame(t(DATA$ContentSorted)) # Zu Data frame konvertieren
	colnames(DATA$ContentDataFrame) <- DATA$Head # Spaltennamen anpassen
	if(!quiet) cat("fertig!\n")
	
	return(DATA$ContentDataFrame) # Dataframe zurückgeben
}


# Datenbereinigung / Aufbereitung des eingelesenen Data.frames
# x: data-frame
FFA.correct.EINSAETZE.data.frame = function(x) {
	DATA = as.data.frame(x) # The data frame
	
	# ganzen Zeitstempel aus Datum und Alarmzeit zusammenbasteln
	DATA$ZEIT <- as.POSIXct(paste(DATA$Datum,DATA$Alarmzeit),format="%n%d.%n%B%n%Y%n%H:%M%n")
	
	# Einsatzdauer aus Stunden und Minuten berechnen
	werte = strsplit(x = as.character(DATA$Dauer), split = "(\\s*Stunden?\\s*)|(\\s*Minuten?\\s*)")
	werte <- lapply(werte,function(x)x[nchar(x)>0]) # sinnlose Leerzellen raus
	einheiten     = strsplit(x = as.character(DATA$Dauer), split = "\\s*[0-9]+\\s*")
	einheiten <- lapply(einheiten,function(x)x[nchar(x)>0]) # sinnlose Leerzellen raus
	DAUER = c()
	for(i in 1:length(einheiten)) {
		einh = einheiten[[i]]
		wert = werte[[i]]
		stundeindex = grep(pattern = "Stunde",einh)
		minuteindex = grep(pattern = "Minute",einh)
		stunde = ifelse(length(wert[stundeindex])>0,as.numeric(wert[stundeindex]),0)
		minute = ifelse(length(wert[minuteindex])>0,as.numeric(wert[minuteindex]),0)
		gesamt = 60 * stunde + minute
		gesamt = ifelse(gesamt>0,gesamt,NA)
		DAUER = c(DAUER,gesamt)
	}
	DATA$EINSATZDAUER.MINUTEN <- DAUER
	
	# Mannschaftsstärke berechnen
	DATA$MANNSCHAFT.GESAMT <- sapply(strsplit(x=as.character(DATA$Mannschaftsstärke),split = "[^0-9]+"),function(x)sum(as.numeric(x)))
	
	# Unnötige Spalten entfernen
	# DATA = DATA[,-grep("(Bilder)|(Presse)|(Video)",colnames(DATA),ignore.case = T)]
	
	# Gallerie aus dem Einsatzbericht entfernen
	# einsatzbericht_ersetzt <- gsub(x=DATA$Einsatzbericht,pattern = "#gallery.*?\\*/",replacement = "")
	# cat("Bericht ohne Galerie:",einsatzbericht_ersetzt,"\n")
	# DATA$Einsatzbericht <- einsatzbericht_ersetzt
	
	# Leerzeilen mit nur NA entfernen
	rows.with.only.na <- apply(DATA,1,function(x)all(is.na(x)))
	DATA <- DATA[!rows.with.only.na,]
	
	return(DATA)
}
