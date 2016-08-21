#!/usr/bin/env jc

load'csv matches.ijs'

Args=: }. ARGV NB. remove jconsole from args list
csvOut=. 3{::Args
(ymatches 2008+i.8) writecsv csvOut
exit''
