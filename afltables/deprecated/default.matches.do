#!/bin/bash -eu

SCRIPT=$(readlink -m "$(type -p $0)")
SCRIPTDIR=$(dirname "$SCRIPT")
source "$SCRIPTDIR/scripts-pipeline/util.sh"

year=${2##*/}
run $SCRIPTDIR/scripts-pipeline/matchstats.sh -y $year -o $3
