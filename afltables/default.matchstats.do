#!/bin/bash -eu

year=${2##*/}
html=matches/$year.matches.html
redo-ifchange $html

stathtmls=$(grep "Match stats" $html | grep -oE "[[:digit:]]+\.html")

mkdir -p $3
for stathtml in $stathtmls; do
    curl http://afltables.com/afl/stats/games/$year/$stathtml > $3/$stathtml
    #w3m -dump -cols 150 -T text/html $3/$stathtml > $3/${stathtml/.html/.txt}
    elinks -dump -dump-width 250 > $3/${stathtml/.html/.txt} < $3/$stathtml
done
