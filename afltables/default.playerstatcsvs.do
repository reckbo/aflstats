#!/bin/bash -eu

source scripts-pipeline/util.sh

year_team=${2##*/}
IFS="-" read year team <<< $year_team
mkdir -p $3
run $SCRIPTDIR/scripts-pipeline/playerstats.R $year $team $3
