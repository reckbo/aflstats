NB. =================
NB. afltables api

load'format/printf'
loc=. 3 : '> (4!:4 <''y'') { 4!:3 $0'
SCRIPTDIR=. getpath_j_ jpath loc''
AFLTABLES_DIR=: SCRIPTDIR,'../afltables/'
STATS=: ;: 'KI MK HB FA FF TK GL HO BH pctP'
statsdir=: (AFLTABLES_DIR,'%s-%s.playerstats')&sprintf@:;
statsfile=: (AFLTABLES_DIR,'%s-%s.playerstats/%s.csv')&sprintf
NB. '2014' statsfiles 'gws'
statsfiles=: 4 : '<@statsfile"1  (<x) ,. (<y),. STATS' 
stattbls=: (STATS&,:)@:(readcsv each)@:statsfiles
