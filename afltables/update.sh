#!/bin/bash -eu

years=$@

[ -n "$years" ] || years=$(date +%Y)

for year in $years; do
    redo $year/$year.matchsummaries.txt
    redo $year/$year.matchstatpages
    while read team; do
        redo $year/$year-$team.playerstatcsvs
    done < playerstatsteams.txt
done
