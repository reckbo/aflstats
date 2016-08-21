loc=. 3 : '> (4!:4 <''y'') { 4!:3 $0'
SCRIPTDIR=. getpath_j_ jpath loc''
load SCRIPTDIR,'../afltables/paths.ijs plot'

NB. -------------------------------------------
NB. player stats

STATS=: ;: 'KI MK HB FA FF TK GL HO BH pctP'
statsfiles=: 4 : '<@statsfile"1  (<x) ,. (<y),. STATS' 
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

NB. -------------------------------------------
NB. match event times

NB.goallines=: #~ 'goal'&(+./@E.)&>
goallines=: #~ ('behind'&E. +./@:+. 'goal'&E.)&>
goaltime=: a: {.@-.~ 1 3&{@:(deb each)@:('|'&cut every)
toSeconds=:60 60&#.@:(".@}: every)@:(' '&splitstring)
fgoaltimes=: toSeconds&> @: goaltime"0 @: goallines @: ('b'&fread)
ygoaltimes=: (fgoaltimes each)@:;@:(mstatfiles each) NB. ygoaltimes 2009 2010

NB.plot ^. h=.(+/\.) (i.1213) (% +/)@:histogram dt=.intervals ygoaltimes 2015
NB.lambda=. 50%4*1200
NB.plot  (^@:-@:(lambda * i.@:#),:]) (+/\.) (i.1213) (% +/)@:histogram dt

NB.cdf=.^@:-@:(lambda * i.@:#) i.1200
NB.plot cdf,:(+/\.) cdf (% +/)@:histogram 1500 ?@:$ 0
simq=.[: }. [: }: (, cdf&I.@:(?&0:))^:(1200 > +/)^:_
simq2=.[: }. [: }: (, (45&+)@:(cdf&I.)@:(?&0:))^:(1200 > +/)^:_
plot +/\. (i.768) (% +/)@:histogram sdt=. ; simq&.> 1500$0
(mean;var;<./;>./) numgoals=._4 +/@:(#&>)\ simq&.> 1500$0
49.9 plotpoiss (i.75);(i.75) (% +/)@:histogram numgoals

quarters=:,@:((<;.1~ (1 , 2 >/\ ]))&>)
NB. intervals ygoaltimes 2014
intervals=: ;@:((2 -~/\ 0&,) each)@:quarters
shiftdiff=:[ |.!.0 (- mean)@:]
NB. Two point correlation
NB.1 2 3 4 5 6 7 8 9 corr"0 1 intervals ygoaltimes 2014
corr=. +/@:*:@:(0&shiftdiff)@:] %~ 0&shiftdiff@:] * shiftdiff

NB.17.5 plotpoiss (i.30);q=.(i.30) (% +/)@:histogram #every d
plotpoiss=: 4 : 0
  'xaxis hist'=. y
  pd'reset'
  pd 'titlefont arial 17 bold italic'
  pd'title AFL scoring events per game'
  pd'xcaption Total scoring events, e'
  pd'ycaption Pr(E = e)'
  pd'key Data, "Poisson (mean=',(":x),')"'
  pd'keycolor red, blue'
  pd'type marker; color red'
  pd 25&}.each  xaxis; hist
  pd'type line; color blue'
  pd 25&}.each xaxis; poissondist x, <:$ xaxis
  pd'show'
)

plottest=: 3 : 0
pd'reset'
pd'penstyle 2 '
pd'pensize 2'
pd y
pd'show'
)

ptest=: 3 : 0
 pd'new'
  pd'type marker'
  pd 5+i.10
  pd'type line'
   pd 'penstyle 0 1 2 3 4'
   pd 'pensize 2'
   pd 'color green,red,blue,magenta,brown'
   pd 'title Line Patterns'
   pd (i.10);y
   pd'show'
 )
