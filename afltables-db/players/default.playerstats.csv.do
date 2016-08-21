#!/usr/bin/env jc

NB. -------------------------------------------
NB. afltables "database" api

load'csv format/printf'
AFLTABLES=: '../../afltables/'
PLAYER_CSVS_DIR=: AFLTABLES,'%s/%s-%s.players/'
NB. statscsvpath 2014;'adelaide';'MK'
statscsvdir=: (PLAYER_CSVS_DIR)&sprintf@:(,~{.)@:(": each)
statscsvpath=: (PLAYER_CSVS_DIR,'%s.csv')&sprintf@:(,~{.)@:(": each)
NB. statscsv 2014;'adelaide';'MK'
statscsv=: readcsv@:statscsvpath

NB. -------------------------------------------
NB. player stats functions

STATS=: ;: 'KI MK HB FA FF TK GL HO BH pctP'
statsfiles=: 4 : '<@statscsvpath"1  (<x) ,. (<y),. STATS' 
stattbls=: (STATS&,:)@:(readcsv each)@:statsfiles
rounds=: ( (-.&'R')each @: {: @: ('.'&splitstring)every) @: }: @: }. @: {.
players=: ({."1)@:}. 
normalizeTbls=: 3 : 0
  StatNames=. {. y
  Tbls=. {: y
  Rounds=: rounds >{. Tbls
  Players=: players >{. Tbls
  NormTbl=. ,/ Players ,."_1 Rounds ,."2  (|:@:(}."1)/.~ {."1) ,/ > }.@:(}:"1) each Tbls
  Hdr=. 'player';'round';STATS
  NB.hdr=:('player';STATS,;:'year round team')
  Hdr,NormTbl 
)

loc=. 3 : '> (4!:4 <''y'') { 4!:3 $0'
SCRIPTDIR=. getpath_j_ jpath loc''

log=: stderr@:(,&LF)
exitMsg=: 3 : 0
    smoutput y
    exit 0
)

Args=: }. ARGV NB. remove jconsole from args list
'Year Team'=. 0 2 { ;: 2{::Args
log 'Year: ' , Year
log 'Team: ' , Team
([: exitMsg 'Source file doesnt exist, skipping'"_)^:-. fexist statscsvdir Year;Team

StatsTbl=.(<Year),. (<Team),. normalizeTbls Year stattbls Team
StatsTbl=.(<'year') (<0 0)} StatsTbl
StatsTbl=.(<'team') (<0 1)} StatsTbl
StatsTbl writecsv 3{::Args

exit 0
