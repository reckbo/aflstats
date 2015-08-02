#!/bin/bash -eu
#
# Dependencies
# * bc

SCRIPT=$(readlink -m $(type -p "$0"))
SCRIPTDIR=${SCRIPT%/*}

usage() {
    echo -e "Usage:
    ${0##*/} [-d] [<year1> <year2> ... <yearN>]
"
}

csplit() {
    if hash gcsplit 2>/dev/null; then
        gcsplit "$@"
    else
        csplit "$@"
    fi
}

split() {
    if hash gsplit 2>/dev/null; then
        gsplit "$@"
    else
        split "$@"
    fi
}

name2sname() {
    sed 1d teamnames.csv | while IFS=, read sname name; do
        sed -i '' "s/${name}/${sname}/g" $1
    done
}

# Output
dirHtml=$SCRIPTDIR/out-html
dirOut=$SCRIPTDIR/out-matchstats
csvMatches=$dirOut/matches.csv
csvTeamMatches=$dirOut/team-matches.csv

# Control info
delim="|"
DEBUG=false

# get list of years
years=""
for arg in $@; do
    [[ "$arg" != "-d" ]] || { DEBUG=true; continue; }
    [[ "$arg" != "-h" ]] || { usage; exit 0; }
    years="$years $arg"
done
[ -n "${years-}" ] || years=$(ls $dirHtml/*.html | xargs basename | cut -d. -f1)

# clear output directory
rm -rf $dirOut/*.csv || true 

# make temporary directory
dirTmp=$(mktemp -d)
echo "Made temporary directory: $dirTmp"
pushd $dirTmp >/dev/null

for year in $years; do
    echo "======= $year ========"

    mkdir $year &>/dev/null || true
    cd $year

    # csv names for each year
    csvMatchesYear=matches.csv
    csvTeamMatchesYear=team-matches.csv

    # get html from website if missing
    html=$(readlink -m "$dirHtml/$year.html")
    [ -f $html ] || curl http://afltables.com/afl/seas/$year.html > $html

    # render html as text
    echo "Render html as text: $html --> $year.txt"
    cat $html | w3m -dump -cols 150 -T text/html > $year.txt

    # Split year text file into AFL rounds
    echo "Split year into AFL rounds: $year.txt --> xx*"
    cat $year.txt | grep -E 'Round |won by|Match drawn|Venue|Preliminary Final|Semi Final|Elimination Final|Qualifying Final|Grand Final' | \
        csplit -f xx -  '/Round \|Final/' '{*}' > /dev/null

    # for each round, make a csv for each match
    echo "Make a csv for each match: xx* --> $year-XX-*.csv"
    printf "filename, roundID, csvRound, csvMatch\n"
    mkdir rounds
    mkdir matches
    for xx in xx*; do
        [[ $xx != xx00 ]] || continue  # first section is empty

        roundid=$(echo $xx | cut -c 3-)
        printf "$xx, $roundid"

        # clean w3m characters by converting to commas
        cat $xx | tr '│' "$delim" | tr '┃' "$delim" | cut -c 2- > $xx

        # make filename/matchid using round's title
        roundTitle=$(sed -n 1p "$xx" | cut -d"$delim" -f1 | tr -d '[[:space:]]')
        csvRound="rounds/$year-$roundid-$roundTitle.csv"

        # save clean data to file
        sed 1d $xx | cut -d"$delim" -f1-4 > $csvRound
        printf ", $csvRound"

        # if a regular season round, split into individual matches
        if  echo $roundTitle | grep -q "Round" ; then
            # Completed rounds only
            if ! grep -Eq 'won by|drawn' $csvRound; then { echo ", No matches yet, skipping"; continue; } fi

            # Sanity check - round should have even number of entries 
            evencheck="$(wc -l < $csvRound | tr -d '[[:space:]]') % 2" 
            [[ $(echo $evencheck | bc) = 0 ]] || { echo "'$csvRound' doesn't have even number of entries"; exit; }

            # Split round into matches
            matchIDprefix="$year-$roundid-"
            split -d --lines 2 --additional-suffix ".csv" $csvRound matches/$matchIDprefix

            printf ", matches/${matchIDprefix}??.csv"
        else # is a final
            mv $csvRound matches/
            printf ", matches/${csvRound##*/}"
        fi

        printf '\n'
    done

    echo "Make a match info row in each match csv"
    for csvMatch in matches/*.csv; do
        gameid=$(echo $csvMatch | xargs basename | cut -d. -f1)
        fileTmp=$(mktemp)
        cat $csvMatch | cut -d"$delim" -f 4 | tr '\n' "$delim" | sed s'/\[Match stats\]//g' > $fileTmp
        cat $csvMatch | cut -d"$delim" -f 1-3 >> $fileTmp
        sed "s/^/$gameid$delim/" $fileTmp |\
            sed "s/[[:space:]]*$delim/$delim/g" |\
            sed "s/$delim[[:space:]]*/$delim/g" |\
            sed "s/$delim$//" |\
            sed 's/\([0-9]\),\([0-9]\)/\1\2/g' > $csvMatch
        rm $fileTmp
    done

    echo "Make $csvMatchesYear and $csvTeamMatchesYear from the match csvs"
    ls matches/*.csv | xargs -n 1 sed -n 1p > $csvMatchesYear
    ls matches/*.csv | xargs -n 1 sed 1d > $csvTeamMatchesYear
    echo "Made '$dirTmp/$year/$csvMatchesYear'"
    echo "Made '$dirTmp/$year/$csvTeamMatchesYear'"
    
    cd ..
done

popd

echo "Combine the team match rows into one csv: $csvTeamMatches"
echo "matchid${delim}team${delim}score_progression${delim}score" > $csvTeamMatches
cat $dirTmp/????/team-matches.csv  |\
    sed "s/[[:space:]]*${delim}/${delim}/g" |\
    sed "s/${delim}[[:space:]]*/${delim}/g" \
    >> $csvTeamMatches

echo "Combine the match rows into one csv, and split column into 4 new fields: venue, attendance, winning team, won by"
echo "matchid${delim}date${delim}attendance${delim}venue${delim}winner${delim}won_by" > $csvMatches
cat $dirTmp/????/matches.csv | \
    sed "s/Att:/${delim}/" | \
    sed "s/Venue: /${delim}/" | \
    sed "s/ won by /${delim}/" | \
    sed 's/ pts//' |\
    sed 's/ pt//' |\
    sed "s/Match drawn/NA${delim}0/" |\
    sed "s/Venue: /${delim}/" |\
    sed "s/[[:space:]]*${delim}/${delim}/g" |\
    sed "s/${delim}[[:space:]]*/${delim}/g" \
    >> $csvMatches
    
echo "Convert delimiter to comma"
sed -i '' "s/${delim}/,/g"  $csvMatches
sed -i '' "s/${delim}/,/g"  $csvTeamMatches

echo "Convert long team names to short ones"
name2sname $csvMatches
name2sname $csvTeamMatches

$DEBUG || rm -rf "$dirTmp"

echo "Made '$csvMatches'"
echo "Made '$csvTeamMatches'"
