NB. ======== 
NB. logic
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
