NB. =================
NB. afltables api

load'format/printf'
loc=. 3 : '> (4!:4 <''y'') { 4!:3 $0'
SCRIPTDIR=. getpath_j_ jpath loc''

DIR_MATCH_STAT_PAGES=:'$year.season/$year.matchstatpages'
DIR_PLAYER_CSVS=:'$year.season/$year-$team.playerstatcsvs'


NB. pstatsdir 2010;'adelaide' 
pstatsdir=: (SCRIPTDIR,'/%s-%s.playerstats')&sprintf@:(": each)
NB. pstatsfile ;:'2010 adelaide KI'
pstatsfile=: (SCRIPTDIR,'players/%s-%s.playerstats/%s.csv')&sprintf@:(": each)
NB. mstatsdir 2009
mstatsdir=: (SCRIPTDIR,'matches/%s.matchstats')&sprintf@:(": each)
mstatfiles=: 1&dir@:('/*.txt' ,~ mstatsdir)
