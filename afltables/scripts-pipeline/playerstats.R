#!/usr/bin/env Rscript

library(XML)
year <- commandArgs(TRUE)[1]
team <- commandArgs(TRUE)[2]
dirOut <- paste0(commandArgs(TRUE)[3],"/")

URL_TEMPLATE="http://afltables.com/afl/stats/teams/_team_/_year__gbg.html"
URL = gsub("_year_", year, gsub("_team_", team, URL_TEMPLATE))
cat(sprintf("URL: %s\n", URL))
tables = readHTMLTable(URL)
names(tables) <- rep(year, length(names(tables)))

KI=tables[2]   # Kicks
MK=tables[3]   # Marks
HB=tables[4]   # Handballs
GL=tables[5]   # Goals
BH=tables[6]   # Behinds
HO=tables[7]   # Hit outs
TK=tables[8]   # Tackles
RB=tables[9]   # Rebound 50s
I5=tables[10]  # Inside 50s
CL=tables[11]  # Clearances
CG=tables[12]  # Clangers
FF=tables[13]  # Free kicks for
FA=tables[14]  # Free kicks against
BR=tables[15]  # Brownlow votes
CP=tables[16]  # Contested possessions
UP=tables[17]  # Uncontested possessions
CM=tables[18]  # Contested marks
MI=tables[19]  # Marks inside 50
OP=tables[20]  # One percenters
BO=tables[21]  # Bounces
GA=tables[22]  # Goal assist
pctP=tables[23]# Percentage of game played
SU=tables[24]  # Sub (On/Off)

write.csv(file=paste0(dirOut,"KI.csv"), x=KI, row.names=FALSE)
write.csv(file=paste0(dirOut,"MK.csv"), x=MK, row.names=FALSE)
write.csv(file=paste0(dirOut,"HB.csv"), x=HB, row.names=FALSE)
write.csv(file=paste0(dirOut,"FA.csv"), x=FA, row.names=FALSE)
write.csv(file=paste0(dirOut,"FF.csv"), x=FF, row.names=FALSE)
write.csv(file=paste0(dirOut,"TK.csv"), x=TK, row.names=FALSE)
write.csv(file=paste0(dirOut,"GL.csv"), x=GL, row.names=FALSE)
write.csv(file=paste0(dirOut,"HO.csv"), x=HO, row.names=FALSE)
write.csv(file=paste0(dirOut,"BH.csv"), x=BH, row.names=FALSE)
write.csv(file=paste0(dirOut,"pctP.csv"), x=pctP, row.names=FALSE)
