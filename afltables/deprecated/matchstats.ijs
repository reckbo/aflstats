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

NB. ('a';'b') in ;: 'ab bc de'
in=:+./@:(+./@:E.&>"0 _)
NB. matchinfo 2 pick Rounds
matchinfo=: _2 {.@:({:"1)\ ]
matchinfos=: splitinfo&>@:matchinfo
NB. removes attendance from round field
NB. e.g.: getround >{. Rounds
getround=:  (deb@:(ROUND_NAMES&stringreplace)@:(7&u:) each)@:{.@:('|'&splitstring) every @: ((<0 0)&{)  


splitinfo=: (<;.1~ ('Att';'Venue')  1&(0})@:(+/)@:(E.every"0 _) <)@:>
team=: 1&{"1
score=: >@:(".each)@:(3&{"1)
winner=:('NA';teams) {~ *@:(-/)@:score
opponent=: |.@:(1&{"1)
date=:('[[:digit:]]+-[[:alpha:]]+-[[:digit:]]+')&rxall@>
year=:('.*-[[:alpha:]]+-([[:digit:]]+) ';1)&rxall@>
venue=:('Venue: (.+)';1)&rxall@>
att=: (". @: (-.&','))each@:(('Att:([[:digit:][:punct:]]+)[[:space:]]+Venue:';1)&rxall)@>

filtertxt=: #~ FILTER_WORDS&in
NB.Filtered=:(#~ FILTER_WORDS&in )'b'fread ftxt 2014
split2rounds=: <;.1~ ('Final';'Round')&in 
splitline=: (4&{."1)@:(<@deb;._1)@((7 u:'│|')&stringreplace)@:(7&u:)

NB.'b'fread ftxt 2014
Rounds=:(_2 (}:"1 ,. winner ,. opponent ,"0 1 (venue, att , year , date)@:{.@:({:"1) )\ ])@:(getround ,. }.)@:(splitline every) each split2rounds filtertxt txt

NB. replace round header with round column
NB.Rounds=: (getround ,. }.) each Rounds
NB. Replace 'won by' and info cells with Date, Attendance, and Venue columns
NB.Rounds=: (}:"1 ,. ,/@:(,:~"1)@:matchinfos)

NB. Add winners column
NB.Rounds=: (,. ,/@:(,:~"0)@:winners) each Rounds
NB. Add opponents column
NB.Rounds=: (,. opponents) each Rounds

NB.m=.readcsv'out-matchstats/matches-2015.csv'
NB.tm=.readcsv'out-matchstats/teammatches-2015.csv
NB.winner=.8{"1 }. m
NB.ha=. 1 5{"1  (,"_1) _2 ]\ }. tm
NB.loser=.winner (] {"0 1~ [={."1@:]) ha
