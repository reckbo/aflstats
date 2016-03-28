load'web/gethttp'
URL_TEMPLATE=:'http://afltables.com/afl/seas/_year_.html'
YEAR=:2014
DELIM=:'│'

url=: URL_TEMPLATE rplc '_year_' ; ":

fhtml=: 3 : 0
  Year=.":y
  Cache=.jpath '~temp/',Year,'.html' 
  if. -. fexist Cache do.
    ('file';Cache) gethttp url Year
  end.
  Cache
)

ftxt=: 3 : 0
 Year=.":y 
  Cache=.jpath '~temp/',Year,'.txt' 
  if. -. fexist Cache do.
    Cmd=.'w3m -dump -cols 150 -T text/html ', fhtml Year
    (shell Cmd) fwrite Cache
  end.
  Cache
)

in=.+./@:(+./@:E.&>"0 _)

FILTER_WORDS=: <;._1'|Round |won by|Match drawn|Venue|Preliminary Final|Semi Final|Elimination Final|Qualifying Final|Grand Final'

Filtered=:(#~ FILTER_WORDS&in )'b'fread ftxt 2014
RoundsRaw=: (<;.1~ ('Final';'Round')&in) Filtered
Rounds=:(4&{."1)@:(<@deb;._1)@((7 u:'│|')&stringreplace)@:(7&u:) every each RoundsRaw

NB.m=.readcsv'out-matchstats/matches-2015.csv'
NB.tm=.readcsv'out-matchstats/teammatches-2015.csv
NB.winner=.8{"1 }. m
NB.ha=. 1 5{"1  (,"_1) _2 ]\ }. tm
NB.loser=.winner (] {"0 1~ [={."1@:]) ha
