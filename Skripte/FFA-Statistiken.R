#!/usr/bin/Rscript
# Skript zum erstellen der Statistiken (Plots)
library(tools)

#### Einstellungen ####
PARAM <- list()
#PARAM$INFILE = "/var/www/FFA/Daten/Einsaetze.csv"
# PARAM$INFILE = ifelse(system("whoami",intern=T)=="pi","/var/www/FFA/Daten/Einsaetze.csv","Daten/Einsaetze.csv")
PARAM$DATAFOLDER = ifelse(system("whoami",intern=T)=="pi","/var/www/FFA/Daten/","Daten/")

for(INFILE in sort(Sys.glob(paste(PARAM$DATAFOLDER,"/Einsaetze-*.csv",sep="")),decreasing = T)) {
	cat("Producing plots for file",INFILE,"...")
	PARAM$INFILE = INFILE
	
	
	PARAM$PLOTBASEFOLDER = ifelse(system("whoami",intern=T)=="pi","/var/www/FFA/Plots/","Plots")
	
	# Plotoptionen
	SETTINGS <- list()
	T->SETTINGS$PNG # Plots als PNG speichern?
	
	
	#### Daten einlesen ####
	# Die Einsatz-Daten werden aus der erstellten CSV-Datei eingelesen
	EINSAETZE <- read.csv(file = PARAM$INFILE,sep=";")
	
	#### Daten vorbereiten ####
	# Das Datum in ein POSIXct-Format konvertieren
	EINSAETZE$ZEIT <- as.POSIXct(EINSAETZE$ZEIT)
	
	#### Plotten ####
	
	#### Variablen ####
	PLOT=list() # Um die Plotvariablen zusammenzuhalten
	
	# Alle Jahre
	PLOT$Jahre = sort(as.integer(na.omit(unique(as.integer(strftime(EINSAETZE$ZEIT,"%Y"))))))
	# Alle Jahre, bis auf das letzte, damit keine unvollständigen Jahre gezählt werden
	# PLOT$Jahre = head(sort(as.integer(na.omit(unique(as.integer(strftime(EINSAETZE$ZEIT,"%Y")))))),-1)
	PLOT$ThisYear = as.integer(strftime(Sys.time(),format="%Y"))
	
	PLOT$JahreText = 
		if(length(PLOT$Jahre) == 1) { # nur ein Jahr
			if(PLOT$Jahre == PLOT$ThisYear) 
				paste("dieses Jahr")
			else 
				paste("in",PLOT$Jahre)
		} else { # mehrere Jahre
			paste("von",min(PLOT$Jahre),"bis",max(PLOT$Jahre))
		}
	
	PARAM$PLOTFOLDERNAME = 
		if(length(PLOT$Jahre) == 1) { # nur ein Jahr
			paste(PLOT$Jahre,sep="+")
		} else { # mehrere Jahre
			"alle"
		}
	
	#### Plotten vorbereiten ####
	
	# PLOT$ImageFeuer = readJPEG("Offline-Resources/Bilder/Feuer.jpg")
	par(bg="white") # Alle sollen standardmäßig weißen Background haben
	# par(bg=NA) # Alle sollen standardmäßig transparenten Background haben
	PLOT$opar = par(no.readonly=T)
	
	#PLOT$PLOTFUN = function(...) png(file=paste("/var/www/FFA/Plots/",PLOT$NAME,".png",collapse="",sep=""),width=400,height=300,res=96,bg="white",...)
	PLOT$PLOTFUN = function(...) {
		folder = paste(PARAM$PLOTBASEFOLDER,PARAM$PLOTFOLDERNAME,sep="/")
		filename = paste(folder,"/",PLOT$NAME,".png",collapse="",sep="")
		# create folder for plots
		system(paste("mkdir","-p",folder))
		
		png(file=filename
				,width=400
				,height=300
				,res=96
				,bg="white"
				,...)
	}
	
	PLOT$Footer = function(){ 
		# Copyright FFA
		# 		mtext(side=1,line=par("mar")[1]-1,
		# 					text=paste("© FF Aumühle,",strftime(Sys.time(),"%Y")),
		# 					adj=1, # Rechtsbündig
		# 					cex=0.9,
		# 					col="#333333"
		# 					)
		mtext(side=1,line=par("mar")[1]-1,
					text="www.feuerwehr-aumuehle.de",
					adj=1, # Rechtsbündig
					cex=0.9,
					col="#333333"
		)
		
		
		# Stand-Datum schreiben
		# Nur wenn Jahre inklusive dem aktuellen geplottet werden
		if(as.integer(strftime(Sys.time(),format="%Y"))%in%PLOT$Jahre) {
			mtext(side=1,line=par("mar")[1]-1,
						text=paste("Stand:",strftime(x=Sys.time(),format="%d.%m.%Y")),
						adj=0, # linksbündig
						cex=0.9,
						col="#333333"
			)
		}
	}
	
	
	#### Einsatz-Barcode ####
	PLOT$NAME = "FFA-Einsaetze-Barcode"
	
	# Plotfunktion aufrufen
	if(SETTINGS$PNG) PLOT$PLOTFUN()
	
	par(mar=c(5,1,4,1)+0.1) # Grafikparameter
	# Einsätze als Barcode
	plot(y=rep(1,length(EINSAETZE$ZEIT))
			 ,x = seq(from=as.POSIXct(paste(min(PLOT$Jahre),"-01-01",sep="")),to=as.POSIXct(paste(max(PLOT$Jahre)+1,"-01-01",sep="")),len=length(EINSAETZE$ZEIT))
			 ,type="n",yaxt="n",ylab="",
			 ,main=paste("Einsatz-Barcode\n",PLOT$JahreText)
			 #xlab=ifelse(length(PLOT$Jahre)==1,"Monat","Zeit")
			 ,xlab = ""
			 ,panel.last=abline(v=EINSAETZE$ZEIT,xpd=F)
			 ,bty = "n" #  keine Box
	)
	
	# abline(v=EINSAETZE$ZEIT,col="red")
	
	# Copyright FFA
	PLOT$Footer()
	
	par(PLOT$opar) # zurücksetzen
	
	#### Häufigkeit nach Jahr ####
	PLOT$NAME = "FFA-Einsaetze-nach-Jahr"
	
	
	# Plotfunktion aufrufen
	if(SETTINGS$PNG) PLOT$PLOTFUN()
	
	# # Anzahl Einsätze nach Tabellenzeilenzahl
	# cat("Einsätze nach Anzahl Zeilen:\n"); for(year in 2009:2015) cat(year,":",length(which(grepl(year,EINSAETZE$Nummer))),"Einsätze\n")
	# # Anzahl Einsätze nach Tabelleneintragnummer
	# cat("Einsätze nach maximaler Nummer:\n"); for(year in 2009:2015) cat(year,":",max(as.numeric(unlist(lapply(strsplit(x=EINSAETZE$Nummer[grepl(year,EINSAETZE$Nummer)],split="[^0-9]+"),function(x)x[1]))),na.rm=T),"Einsätze\n")
	
	PLOT$JahreAnzahl = c()
	for(year in PLOT$Jahre) { # Suche maximalen Nummer-Eintrag
		# 	PLOT$JahreAnzahl[match(year,PLOT$Jahre)] = max(as.numeric(unlist(lapply(strsplit(x=EINSAETZE$Nummer[grepl(year,EINSAETZE$Nummer)],split="[^0-9]+"),function(x)x[1]))),na.rm=T)
		PLOT$JahreAnzahl[match(year,PLOT$Jahre)] = length(which(strftime(EINSAETZE$ZEIT,format="%Y")==year))
	} ;rm(year)
	
	
	# Barplot
	par(mar=c(4,2,4,2)+0.1)
	PLOT$JahreBarplot = barplot(height=PLOT$JahreAnzahl,
															names.arg=PLOT$Jahre,
															col=terrain.colors(length(PLOT$Jahre)),
															main=paste("Anzahl Einsätze pro Jahr\n",PLOT$JahreText),
															xlab="",
															yaxt="n",
															ylim=c(0,max(PLOT$JahreAnzahl)*1.2)
	)
	# Anzahl hinschreiben
	text(x = PLOT$JahreBarplot,y=PLOT$JahreAnzahl,labels = PLOT$JahreAnzahl
			 ,pos=3
			 )
	
	# Copyright FFA
	PLOT$Footer()
	
	par(PLOT$opar) # zurücksetzen
	
	
	#### Häufigkeit nach Einsatzart ####
	PLOT$NAME = "Einsatzhaeufigkeit-nach-Art"
	
	# Plotfunktion aufrufen
	if(SETTINGS$PNG) PLOT$PLOTFUN()
	
	# Splitte die Einsatzarten
	PLOT$EinsatzArten = strsplit(as.character(EINSAETZE$Art),"\\s*>\\s*")
	# Entferne unnötige Zeichen an Anfang und Ende der Einsatzarten
	PLOT$EinsatzArten = lapply(PLOT$EinsatzArten,function(x)gsub(x = x,pattern = "^[^a-zA-Zäüö,]|[^a-zA-Zäüö,]$",replacement ="")) 
	PLOT$EinsatzArten = lapply(PLOT$EinsatzArten,function(x)gsub(x = x,pattern = "^\\s*|\\s*$",replacement ="")) 
	PLOT$EinsatzArtenHauptAlle = sapply(PLOT$EinsatzArten,function(x)x[1])
	PLOT$EinsatzArtenHaupt = unique(PLOT$EinsatzArtenHauptAlle)
	
	PLOT$EinsatzArtenHaeufigkeit = c()
	for(ART in PLOT$EinsatzArtenHaupt) {
		PLOT$EinsatzArtenHaeufigkeit = c(PLOT$EinsatzArtenHaeufigkeit,length(which(PLOT$EinsatzArtenHauptAlle==ART)))
	}
	PLOT$EinsatzArtenHaeufigkeit = data.frame(Art=PLOT$EinsatzArtenHaupt,Anzahl=PLOT$EinsatzArtenHaeufigkeit)
	PLOT$EinsatzArtenFarbe = list(
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
	
	PLOT$EinsatzArtenFarbeVector = unlist(lapply(as.character(PLOT$EinsatzArtenHaupt), function(x)ifelse(is.null(PLOT$EinsatzArtenFarbe[[x]]),NA,PLOT$EinsatzArtenFarbe[[x]])))
	
	# Torte zeichnen
	par(mar=c(0,0,2,0)) # Weniger Rand
	PLOT$EinsatzArtenFarbenSortiert = PLOT$EinsatzArtenFarbeVector[order(PLOT$EinsatzArtenHaeufigkeit$Anzahl)]
	PLOT$EinsatzArtenLabelsSortiert = PLOT$EinsatzArtenHaeufigkeit$Art[order(PLOT$EinsatzArtenHaeufigkeit$Anzahl)]
	PLOT$EinsatzArtenHaeufigkeitenSortiert = PLOT$EinsatzArtenHaeufigkeit$Anzahl[order(PLOT$EinsatzArtenHaeufigkeit$Anzahl)]
	PLOT$EinsatzArtenLabelsAussortiert = PLOT$EinsatzArtenLabelsSortiert
	PLOT$EinsatzArtenZuKleinIndex = which(PLOT$EinsatzArtenHaeufigkeitenSortiert/sum(PLOT$EinsatzArtenHaeufigkeitenSortiert)<0.015)
	PLOT$EinsatzArtenLabelsAussortiert[PLOT$EinsatzArtenZuKleinIndex] = NA
	PLOT$EinsatzArtenLabelsAussortiertIndex = setdiff(seq_along(PLOT$EinsatzArtenLabelsAussortiert),PLOT$EinsatzArtenZuKleinIndex)
	
	pie(x=PLOT$EinsatzArtenHaeufigkeitenSortiert,
			labels = ifelse(is.na(PLOT$EinsatzArtenLabelsAussortiert),NA,paste(PLOT$EinsatzArtenLabelsAussortiert," (",PLOT$EinsatzArtenHaeufigkeitenSortiert,")",sep="")),
			border = "black",
			init.angle=180, # Drehen
			main=paste("Einsatzhäufigkeit nach Einsatzart\n",PLOT$JahreText),
			col=PLOT$EinsatzArtenFarbenSortiert,
			radius=0.65,
			cex=0.8
	)
	
	if(length(PLOT$EinsatzArtenZuKleinIndex) > 0) {
		legend(x="topright",
					 legend=paste(PLOT$EinsatzArtenLabelsSortiert[PLOT$EinsatzArtenZuKleinIndex]," (",PLOT$EinsatzArtenHaeufigkeitenSortiert[PLOT$EinsatzArtenZuKleinIndex],")",sep=""),
					 # 			 col=PLOT$EinsatzArtenFarbenSortiert[PLOT$EinsatzArtenZuKleinIndex],
					 # 			 pch=20,
					 border="black",
					 bty="n",
					 cex=0.8,
					 fill=PLOT$EinsatzArtenFarbenSortiert[PLOT$EinsatzArtenZuKleinIndex]
		)
	}
	
	# Copyright FFA
	PLOT$Footer()
	
	
	par(PLOT$opar) # Grafikparameter zurücksetzen
	
	
	#### Häufigkeit nach Wochentag ####
	# Barplot
	PLOT$NAME = "FFA-Einsaetze-nach-Wochentag-Barplot"
	
	# Plotfunktion aufrufen
	if(SETTINGS$PNG) PLOT$PLOTFUN()
	
	# Geplante / terminierte Einsätze ausgenommen (z.B. Brandsicherheitswache)
	PLOT$WochentageEinsaetze = strftime(x = EINSAETZE$ZEIT[!grepl("Termin",EINSAETZE$Alarmierungsart)], format = "%A")
	PLOT$Wochentage = c("Montag","Dienstag","Mittwoch","Donnerstag","Freitag","Samstag","Sonntag")
	for(Tag in PLOT$Wochentage) PLOT$WochentageHaeufigkeit[match(Tag,PLOT$Wochentage)] = length(which(PLOT$WochentageEinsaetze==Tag)); rm(Tag)
	PLOT$WochentageHaeufigkeit = PLOT$WochentageHaeufigkeit / length(PLOT$WochentageEinsaetze)
	PLOT$WochentageColors = c(colorRampPalette(c("yellow","darkorange"))(5),colorRampPalette(c("darkgreen","green4"))(2))
	PLOT$WochentageColors[PLOT$WochentageHaeufigkeit==max(PLOT$WochentageHaeufigkeit)] = "red"
	
	par(mar=c(4,2,3,2)+0.1) # Ränder anpassen
	PLOT$WochentageBarplot = barplot(height = PLOT$WochentageHaeufigkeit * 100,
																	 names.arg = PLOT$Wochentage,
																	 main=paste("Einsatzhäufigkeit nach Wochentag\n",PLOT$JahreText),
																	 ylab="Anteil an allen Einsätzen [%]",
																	 col=PLOT$WochentageColors,
																	 yaxt="n",
																	 ylim=c(0,max(PLOT$WochentageHaeufigkeit*100)*1.2)
	)
	text(x = PLOT$WochentageBarplot,y=PLOT$WochentageHaeufigkeit*100,
			 labels = sprintf("%i%%",as.integer(PLOT$WochentageHaeufigkeit*100)),pos=3
			 )
	
	# Copyright FFA
	PLOT$Footer()
	
	
	
	# Tortendiagramm
	PLOT$NAME = "FFA-Einsaetze-nach-Wochentag-Torte"
	
	# Plotfunktion aufrufen
	if(SETTINGS$PNG) PLOT$PLOTFUN()
	
	par(mar=c(0,0,4,0)) # Weniger Rand
	pie(PLOT$WochentageHaeufigkeit,
			labels = ifelse(PLOT$WochentageHaeufigkeit>0,paste(PLOT$Wochentage," (",sprintf("%.0f%%",PLOT$WochentageHaeufigkeit*100),")",sep=""),NA),
			col = PLOT$WochentageColors,
			init.angle=180,
			cex = 0.8,
			clockwise=T,
			main=paste("Einsatzhäufigkeit nach Wochentag *\n",PLOT$JahreText),
	)
	
	# Copyright FFA
	PLOT$Footer()
	
	
	par(PLOT$opar) # Ränder zurücksetzen
	
	#### Häufigkeit nach Uhrzeit ####
	PLOT$NAME = "FFA-Einsaetze-nach-Uhrzeit"
	
	# Plotfunktion aufrufen
	if(SETTINGS$PNG) PLOT$PLOTFUN()
	
	PLOT$UhrzeitCT = as.POSIXct(strftime(x=EINSAETZE$ZEIT,format = "%H:%M:%S"),format="%H:%M:%S")
	PLOT$HourColorsSequence = sin(seq(f=0,t=pi,l=24))^1.8 # Eine Sequenz für die Grauskala
	PLOT$HourColors = gray(PLOT$HourColorsSequence) # Die Farbskala
	# Grafikparameter
	par(mar=c(4,2,3,2)+0.1)
	# Histogramm
	# Terminierte / abgesprochene Einsätze rausgenommen (z.B. Brandsicherheitswache)!
	hist(PLOT$UhrzeitCT[!grepl("Termin",EINSAETZE$Alarmierungsart)],breaks="hour",right=F,
			 main=paste("Einsatzhäufigkeit nach Uhrzeit *\n",PLOT$JahreText),
			 xlab="",
			 yaxt="n",ylab="",
			 cex.axis=0.8,
			 col=PLOT$HourColors
	)
	
	# Copyright FFA
	PLOT$Footer()
	
	
	par(PLOT$opar) # Zurücksetzen
	
	#### Häufigkeit nach Monat ####
	PLOT$NAME = "FFA-Einsaetze-nach-Monat"
	
	# Plotfunktion aufrufen
	if(SETTINGS$PNG) PLOT$PLOTFUN()
	
	# Einsatzzeiten aller vollen Jahre
	PLOT$JahreEinsaetzZeiten = EINSAETZE$ZEIT[as.numeric(strftime(x = EINSAETZE$ZEIT,format = "%Y"))%in%PLOT$Jahre]
	# Die Monate dazu
	PLOT$JahreMonate = as.numeric(strftime(x = PLOT$JahreEinsaetzZeiten,format = "%m"))
	PLOT$JahreEinsaetzZeiten<-NULL # Speicherplatz sparen
	
	PLOT$Monate = c("Januar","Februar","März","April","Mai","Juni","Juli","August","September","Oktober","November","Dezember")
	PLOT$Monate = c("Jan","Feb","März","April","Mai","Juni","Juli","Aug","Sep","Okt","Nov","Dez")
	PLOT$MonateColors = colorRampPalette(c("gray","green4","yellow","brown","gray"))(length(PLOT$Monate))
	PLOT$MonateAnzahl = c()
	for(monat in 1:12) { # Alle Monate durchgehen
		PLOT$MonateAnzahl[monat] = length(which(PLOT$JahreMonate==monat))
	} ;rm(monat)
	PLOT$MonateAnteil = PLOT$MonateAnzahl / sum(PLOT$MonateAnzahl)
	
	# Barplot
	par(mar=c(5,2,3,2)+0.1)
	PLOT$MonateBarplot = barplot(height=PLOT$MonateAnteil,
															 names.arg=PLOT$Monate,
															 col=PLOT$MonateColors,
															 main=paste(ifelse(length(PLOT$Jahre)==1,"Anzahl Einsätze nach Monat","mittl. Anzahl Einsätze pro Monat"),"\n",PLOT$JahreText,sep=""),
															 #xlab="Monat",
															 yaxt="n",
															 ylim=c(0,max(PLOT$MonateAnteil)*1.2),
															 las=2
	)
	# Anzahl hinschreiben
	if(length(PLOT$Jahre)==1) {
		text(x = PLOT$MonateBarplot,y=PLOT$MonateAnteil,labels = PLOT$MonateAnzahl,pos=3)
	} else {
		text(x = PLOT$MonateBarplot,y=PLOT$MonateAnteil,labels = sprintf("%.1f",PLOT$MonateAnzahl/length(PLOT$Jahre)),pos=3,cex=0.8)
	}
	
	# Copyright FFA
	PLOT$Footer()
	
	
	par(PLOT$opar) # Grafikparameter zurücksetzen
	
	
	#### Mannschaftsstärke nach Uhrzeit ####
	PLOT$NAME = "Mannschaftsstaerke-nach-Uhrzeit"
	
	# Plotfunktion aufrufen
	if(SETTINGS$PNG) PLOT$PLOTFUN()
	
	# Stunden von 00 Uhr bis 24 Uhr als POSIXct
	PLOT$Hours = seq(f=as.POSIXct(x="00",format="%H"),t=as.POSIXct(x="00",format="%H")+60*60*24-1,by="hours")
	# Auf Stunden reduzierte Einsätze
	PLOT$EinsaetzeHours = as.POSIXct(x=strftime(x=EINSAETZE$ZEIT,format="%H"),format="%H")
	# Gemittelte Mannschaftsstärke nach Zeit
	PLOT$MannschaftproZeit = c()
	
	# Terminierte / abgesprochene Einsätze rausgenommen (z.B. Brandsicherheitswache)!
	for(hour in PLOT$Hours) PLOT$MannschaftproZeit = c(PLOT$MannschaftproZeit,mean(EINSAETZE$MANNSCHAFT.GESAMT[which(PLOT$EinsaetzeHours==hour&!grepl("Termin",EINSAETZE$Alarmierungsart))],na.rm = T))
	
	par(mar=c(3,2,3,2)+0.1)
	
	# Barplot
	PLOT$MannschaftBarplot=barplot(PLOT$MannschaftproZeit, # Werte
																 names.arg = strftime(PLOT$Hours,format="%H:00"), # X-Achse
																 # 				las=2,
																 # 				tcl=0.5, # Achsenzeichen
																 main=paste("Mittlere Mannschaftsstärke im Einsatz nach Uhrzeit *\n",PLOT$JahreText),
																 cex.main=0.9,
																 col=PLOT$HourColors,
																 xaxt="n",
																 las=2,
																 cex.axis=0.8
	)
	axis(1,tick=F,at=PLOT$MannschaftBarplot,labels=paste(0:23,":00",sep=""),cex.axis=0.7,line=-1)
	
	# Linien einzeichnen
	abline(h=9,col="#eeeeeeaa",lwd=17)
	text(x=mean(c(par("usr")[1],par("usr")[2])),y = 9,labels = "HLF Besatzung - 8 Kameraden",font=2)
	
	# Copyright FFA
	PLOT$Footer()
	
	par(PLOT$opar) # Grafikparameter zurücksetzen
	
	#### Einsatzdauer nach Einsatzart ####
	PLOT$NAME = "FFA-Einsatzdauer-nach-Art"
	
	# Plotfunktion aufrufen
	if(SETTINGS$PNG) PLOT$PLOTFUN()
	
	PLOT$EinsatzArtenDauer <- c()
	for(ART in PLOT$EinsatzArtenHaupt) {
		PLOT$EinsatzArtenDauer = c(PLOT$EinsatzArtenDauer,mean(which(PLOT$EinsatzArtenHauptAlle==ART),na.rm = T))
	}
	PLOT$EinsatzArtenDauer <- PLOT$EinsatzArtenDauer / 60
	
	PLOT$EinsatzArtenFarbeCompVector <- unlist(lapply(PLOT$EinsatzArtenFarbeVector,function(color)do.call(rgb, as.list(1 - col2rgb(color) / 255))))
	
	# Barplot
	par(mar=c(2,1,3,1)+0.1)
	PLOT$EinsatzArtenDauerBarplot = barplot(height=PLOT$EinsatzArtenDauer[rev(order(PLOT$EinsatzArtenDauer))],
																					names.arg=PLOT$EinsatzArtenHaupt[rev(order(PLOT$EinsatzArtenDauer))],
																					col=PLOT$EinsatzArtenFarbeVector[rev(order(PLOT$EinsatzArtenDauer))],
																					main=paste("Mittlere Einsatzdauer nach Einsatzart\n",PLOT$JahreText),
																					ylab="mittl. Einsatzdauer in Stunden",
																					yaxt="n",
																					xaxt="n",
																					ylim=c(0,max(PLOT$EinsatzArtenDauer,na.rm=T)*1.1),
																					
	)
	
	legend(x="topright",legend = "in Minuten",bty='n',cex=0.8)
	text(x = PLOT$EinsatzArtenDauerBarplot,y=PLOT$EinsatzArtenDauer[rev(order(PLOT$EinsatzArtenDauer))],
			 labels = sprintf("%i",as.integer(PLOT$EinsatzArtenDauer[rev(order(PLOT$EinsatzArtenDauer))]*60)),
			 pos=3,offset=0.2,cex=0.7)
	
	
	# Arten hinschreiben
	text(x = PLOT$EinsatzArtenDauerBarplot,
			 y=PLOT$EinsatzArtenDauer[rev(order(PLOT$EinsatzArtenDauer))]/2,
			 # 		 y=0,
			 srt=90,
			 font=2,
			 adj=0.5,
			 col=gray(apply(col2rgb(col = PLOT$EinsatzArtenFarbeCompVector),2,function(x)ifelse(mean(x)>256/2,256,0))/256)[rev(order(PLOT$EinsatzArtenDauer))],
			 cex=0.6,
			 labels = PLOT$EinsatzArtenHaupt[rev(order(PLOT$EinsatzArtenDauer))])
	
	# axis(2,at=seq(f=0,t=floor(max(PLOT$EinsatzArtenDauer)),by=1),las=2)
	
	# Copyright FFA
	PLOT$Footer()
	
	par(PLOT$opar) # Grafikparameter zurücksetzen
	
	
	#### Einsatzarten Häufigkeit in Monaten ####
	PLOT$NAME = "FFA-Einsatzarten-nach-Monat"
	
	# Plotfunktion aufrufen
	if(SETTINGS$PNG) PLOT$PLOTFUN()
	
	# Einsatzhäufigkeit nach Monat und Art in Matrix speichern
	# Zeile: Häufigkeit einer Einsatzart in jedem Monat
	# Spalte: Aufteilung Einsatzarten in einem Monat
	PLOT$EinsaetzeMonateArten = matrix(0,ncol=length(PLOT$Monate),nrow=length(PLOT$EinsatzArtenHaupt))
	for(art in PLOT$EinsatzArtenHaupt){
		for(monat in PLOT$Monate) {
			PLOT$EinsaetzeMonateArten[match(art,PLOT$EinsatzArtenHaupt),match(monat,PLOT$Monate)] = length(which(match(monat,PLOT$Monate)==as.integer(strftime(x = EINSAETZE$ZEIT,format="%m"))&art==PLOT$EinsatzArtenHauptAlle))
		}
	}
	
	# Barplot
	par(mar=c(4,2,3,2)+0.1)
	PLOT$MonateBarplot = barplot(height=PLOT$EinsaetzeMonateArten,
															 names.arg=PLOT$Monate,
															 col=PLOT$EinsatzArtenFarbeVector,
															 main=paste("Verteilung der Einsatzarten im Jahr\n",PLOT$JahreText),
															 #xlab="Monat",
															 yaxt="n",
															 ylim=c(0,max(apply(PLOT$EinsaetzeMonateArten,2,sum),na.rm=T)*1.2),
															 las=2
	)
	
	# legend("topleft",legend=PLOT$EinsatzArtenHaupt,col=PLOT$EinsatzArtenFarbeVector,lty=1,lwd=2,bty="n",cex=0.7)
	legend("topleft",legend="Farben wie in Einsatzarten-Grafik",bty="n",cex=0.7)
	
	
	# Copyright FFA
	PLOT$Footer()
	
	par(PLOT$opar) # Grafikparameter zurücksetzen
	
	
	#### Aufräumen ####
	
	# Alle offenen PNGs schließen
	for(dev in as.numeric(dev.list()[which(names(dev.list())=="png")])) { dev.off(dev) }; rm(dev)
	
	cat("fertig!\n")
}