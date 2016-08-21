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

ftxt=: 3 : 0 "0
 Year=.":y 
  Cache=.jpath '~temp/',Year,'.txt' 
  if. -. fexist Cache do.
    Cmd=.'w3m -dump -cols 150 -T text/html ', fhtml Year
    (shell Cmd) fwrite Cache
  end.
  Cache
)

NB. -------------------------------------------------
NB. Logic

ROUND_NAMES=: , ('|'&splitstring);._2 [ 0 : 0
Round|
Preliminary Final|PF
Semi Final|SF
Elimination Final|EF
Qualifying Final|QF
Grand Final|GF
)

NB.FILTER_WORDS=: <;._1'|Round |won by|Match drawn|Venue|Preliminary Final|Semi Final|Elimination Final|Qualifying Final|Grand Final'
FILTER_WORDS=: <;._1'|Round |Match stats|Venue|Preliminary Final|Semi Final|Elimination Final|Qualifying Final|Grand Final'
in=:+./"1@:(+./@E.&>"1 0)

NB. Preprocessing verbs
filtertxt=: #~ FILTER_WORDS&in
NB.Filtered=:(#~ FILTER_WORDS&in )'b'fread ftxt 2014
split2rounds=: <;.1~ ('Final';'Round')&in 
splitline=: (4&{."1)@:(<@deb;._1)@((7 u:'│|')&stringreplace)@:(7&u:)
getround=:  (deb@:(ROUND_NAMES&stringreplace)@:(7&u:) each)@:{.@:('|'&splitstring) every @: ((<0 0)&{)  

NB. Verbs applied to 2xN match tables
team=: 1&{"1
teams=: 1&{"1
score=: >@:(".each)@:(3&{"1)
winner=:('NA';teams) {~ *@:(-/)@:score
opponent=: |.@:(1&{"1)
date=:('[[:digit:]]+-[[:alpha:]]+-[[:digit:]]+')&rxall@>
year=:('.*-[[:alpha:]]+-([[:digit:]]+) ';1)&rxall@>
venue=:('Venue: (.+)';1)&rxall@>
att=: (". @: (-.&','))each@:(('Att:([[:digit:][:punct:]]+)[[:space:]]+Venue:';1)&rxall)@>
NB.splitinfo=: (<;.1~ ('Att';'Venue')  1&(0})@:(+/)@:(E.every"0 _) <)@:>
matchinfo=:(}:"1 ,. winner ,. opponent ,"0 1 (venue, att , year , date, ('-' <@joinstring date , venue))@:{.@:({:"1) )

yrounds=: 3 : ',/each (_2 matchinfo\ ])@:(getround ,. }.)@:(splitline every) each split2rounds filtertxt ''b'' fread ftxt  y'
ymatches=: ;@:(;@yrounds each)

