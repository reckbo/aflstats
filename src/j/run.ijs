require'data/jdb'

NB.hf=: 
NB.InsertCols__hd 'matches';0 : 0
NB.matchid varchar
NB.date varchar 
NB.att int
NB.venue varchar
NB.winner varchar
NB.won_by int
NB.)
NB.row=:(<'1990-01-00');(<'Sat 31-Mar-1990 2:10 PM');22427;(<'Princes Park');(<'Sydney');5
NB.Insert__hd'matches';<row

Drop__f 'afl'
d=: Create__f 'afl'

NB.matchCols=: 0 : 0
NB.matchid int
NB.matchid varchar
NB.att int
NB.)
NB.t=:Create__d'match';matchCols; <9;'2015';3
NB.Insert__d'match';<3;'2016';900


matchCols=: 0 : 0
matchid varchar
matchid int
att int
)
Create__d'match';matchCols; <(<'2015');9;3 NB. fails
