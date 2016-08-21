#!/bin/bash -eu

years=$@

[ -n "$years" ] || years=$(date +%Y)

for year in $years; do
    redo $year/$year.matches.txt
    redo $year/$year.matchstats
    while read team; do
        redo $year/$year-$team.players
    done < playerstatsteams.txt
done
