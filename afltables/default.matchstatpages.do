#!/bin/bash -eu

[ ! -d "$1" ]  || { echo "'$1' already exists."; exit 0; }

year=${2##*/}
html=$year/$year.matchsummaries.html
redo-ifchange $html

stathtmls=$(grep "Match stats" $html | grep -oE "[[:digit:]]+\.html")

mkdir -p $3
for stathtml in $stathtmls; do
    curl http://afltables.com/afl/stats/games/$year/$stathtml > $3/$stathtml
    #w3m -dump -cols 150 -T text/html $3/$stathtml > $3/${stathtml/.html/.txt}
    elinks -dump -dump-width 250 > $3/${stathtml/.html/.txt} < $3/$stathtml
done
