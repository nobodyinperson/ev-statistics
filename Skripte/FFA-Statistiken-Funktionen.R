#!/usr/bin/Rscript
# Funktionen zum Auslesen von HTML Tabellen

#### Funktionen definieren ####
# Zusammenfügen zweier Data frames
concatenate.data.frames = function(x,y,fill=NA) {
	for(col in setdiff(colnames(y),colnames(x))) x[col] = fill
	for(col in setdiff(colnames(x),colnames(y))) y[col] = fill
	return(rbind(x,y))
}



# Die Bibliothek RCurl macht Probleme (crasht, oder ist für bestimmte R-Versionen nicht verfügbar)
# also bieten diese Funktionen einen einfachen Ersatz durch wget

# Gibt zurück, ob die gegebene URL existiert oder nicht
FFA.url.exists = function(url="") {
# 	if(require(RCurl,q=T)) { # Es gibt RCurl, dann nutze es auch!
# 		return(url.exists(url))
# 	} else { # Ohne RCurl, nimm wget
		if(nchar(url)==0) return(FALSE)
		cmd = paste("wget --spider -q",shQuote(url)) # Commandline mit wget, URL gequotet
		res = system(cmd) # Exit-Code des wget lesen
		return(res==0) # zurückgeben, ob Exitcode == 0
# 	}
	
}

# Lädt den Inhalt der URL runter
FFA.get.url = function(url="") {
	empty = "" # Rückgabewert bei Fehlschlag
	if(nchar(url)==0) { # If the url has no characters
		warning("Argument 'url' is empty. Won't download anything.")
		return(empty)
		}
	if(!FFA.url.exists(url)) { # If the url does not exist, return FALSE
		warning(paste("URL: »",url,"« is non existant. Could not download anything.",sep=""))
		return(empty)
		}
# 	if(require(RCurl,q=T)) { # Es gibt RCurl, dann nutze es auch!
# 		return(getURL(url))
# 	} else { # Benutze WGET, wenn es kein RCurl gibt
# 		cmd = paste("wget -qO-",shQuote(url)) # wget-Befehl
# 		res = system(cmd,intern=T) # Runterladen
		con <- url(url)		
		res <- readLines(con,warn=F)
		on.exit(close(con))
		return(paste(res,collapse="\n")) # Zeilen zusammenfügen und zurückgeben
# 		}
	}



# Aus HTML-Quelltext Elemente raussuchen
# HTML kann eine oder mehrere "XMLDocumentContent" oder URLs sein, der Quelltext wird dann runtergeladen
# xpath ist ein oder mehrere xpaths (also Strings), nach denen in HTML gesucht werden soll
# ... sind weitere Argumente an die Funktion xpathApply (wie bspw. xmlAttrs, um die Attribute zu bekommen)
# Gibt alle durch xpath gefundenen Elemente zurück
FFA.XPath.from.HTML = function(HTML,xpath="/*",quiet=F,...) {
	# Benötigte Bibliotheken
	library(XML)
	
	### Quellen zusammenstellen ###
	# Gucken, wie viele Elemente als Quellen übergeben wurden
	if(length(HTML)<1) { # Zu wenig Elemente angegeben
		warning("Argument HTML muss ein oder mehrere URLs oder ein oder mehrere 'XMLInternalDocument' oder 'XMLInternalNode' sein!")
		return(NULL) # Nichts zurückgeben
	}
	else { # Es wurden Quellen angegeben
		SOURCES = list() # Leere Liste für alle Quellen
		count=1 # Schleifenzählvariable
		for(Source in HTML) { # Alle Quellen durchgehen
			if(is.character(Source)) { # Diese Quelle wurde als String angegeben
				if(FFA.url.exists(Source)) { # Diese Quelle ist eine URL
					if(!quiet) cat("Download: »",Source,"« ... ",sep="")
					Source = FFA.get.url(Source)
					if(!quiet) cat("fertig!\n")
				}
				# Wenn diese Quelle keine URL ist, nimm an, dass es HTML-Quellcode ist
				Source = htmlTreeParse(Source,useInternalNodes = T) # HTML einlesen
			}
			
	
			# Hänge nur an, wenn Quelle jetzt als XML interpretierbar ist
			if(any(class(Source)=="XMLInternalDocument"|class(Source)=="XMLInternalNode"))
				SOURCES[[length(SOURCES)+1]] = Source # An Quellenliste anhängen
			else # Irgendwas stimmt nicht...
				warning("Das ",count,". Element im HTML-Argument kann nicht zu einem XML-Tree verarbeitet werden! Wird ausgelassen.")
			
			count = count + 1 # Hochzählen
		}
	}
	
	# Die XMLInternalDocuments, auf die xpaths angewendet werden können, liegen jetzt in der Liste SOURCES
	### Jetzt die xpaths raussuchen ###
	# Füge alle xpaths zusammen
	if(is.character(xpath) & length(xpath)>0)
		xpath = paste(xpath,sep=" | ")
	else { # Der gegebene xpath ist Mist...
		warning("Das Argument 'xpath' muss ein oder mehrere XPath sein. (Ach was!). Es wird XPath '/*' angenommen!")
		xpath="/*"
	}
	
	# Die Elemente raussuchen
	RESULT = unlist(lapply(SOURCES,xpathApply,path=xpath,...))
	return(RESULT) # Zurückgeben
}



