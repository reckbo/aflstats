#!/bin/bash -eu

source scripts-pipeline/util.sh

if [ ! -d "$1" ]; then
    year_team=${2##*/}
    echo $year_team
    IFS="-" read -r year team <<< "$year_team"
    echo $year
    echo $team
    if [ $year -lt 2012 ] && [ "$team" = 'gws' ]; then
        log "Ignoring gws for year $year"
        exit 0;
    elif [ $year -lt 2011 ] && [ "$team" = 'goldcoast' ]; then
        log "Ignoring goldcoast for year $year"
        exit 0;
    fi
    mkdir -p $3
    run $SCRIPTDIR/scripts-pipeline/playerstats.R $year $team $3
else
    log "Directory already exists: $1'"
 fi
