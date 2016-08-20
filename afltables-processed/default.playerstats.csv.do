#!/usr/bin/env jconsole

loc=. 3 : '> (4!:4 <''y'') { 4!:3 $0'
SCRIPTDIR=. getpath_j_ jpath loc''

log=: stderr@:(,&LF)

load'csv format/printf ',SCRIPTDIR,'/lib.ijs'

Args=: }. ARGV NB. remove jconsole from args list
'Year Team'=. 0 2 { ;: 2{::Args
log 'Year: ' , Year
log 'Team: ' , Team

StatsDir=. statsdir Year;Team
shell('redo-ifchange ', StatsDir)
StatsTbl=.(<Year),. (<Team),. normalizeTbls Year stattbls Team
StatsTbl=.(<'year') (<0 0)} StatsTbl
StatsTbl=.(<'team') (<0 1)} StatsTbl
StatsTbl writecsv 3{::Args

exit 0
