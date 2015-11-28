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
    sed 1d "$SCRIPTDIR"/teamnames.csv | while IFS=, read sname name; do
        sed -i '' "s/${name}/${sname}/g" $1
    done
}

# Output
dirHtml=$SCRIPTDIR/out-html
dirOut=$SCRIPTDIR/out-matchstats

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
[ -n "${years-}" ] || years=$(seq 1990 2015)

# make temporary directory
dirTmp=$(mktemp -d)
echo "Made temporary directory: $dirTmp"
pushd $dirTmp >/dev/null

for year in $years; do
    echo "======= $year ========"

    mkdir $year &>/dev/null || true
    cd $year

    # csv names for each year
    csvMatchesYear=matches-${year}.csv
    csvTeamMatchesYear=teammatches-${year}.csv

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
    ls matches/*.csv | xargs -n 1 sed -n 1p > matches-tmp.csv
    ls matches/*.csv | xargs -n 1 sed 1d > teammatches-tmp.csv

    echo "matchid${delim}team${delim}score_progression${delim}score" > $csvTeamMatchesYear
    cat teammatches-tmp.csv |\
        sed "s/[[:space:]]*${delim}/${delim}/g" |\
        sed "s/${delim}[[:space:]]*/${delim}/g" \
        >> $csvTeamMatchesYear

    echo " Split column into new fields"
    echo "year${delim}matchid${delim}day${delim}date${delim}time${delim}atime${delim}attendance${delim}venue${delim}winner${delim}won_by,extra_time" > $csvMatchesYear
    cat matches-tmp.csv | \
        sed "s/Att:/${delim}/" | \
        sed "s/Venue: /${delim}/" | \
        sed "s/ won by /${delim}/" | \
        sed 's/ pts//' |\
        sed 's/ pt//' |\
        sed "s/Match drawn/NA${delim}0/" |\
        sed "s/Venue: /${delim}/" |\
        sed "s/[[:space:]]*${delim}/${delim}/g" |\
        sed "s/${delim}[[:space:]]*/${delim}/g" |\
        sed "s/$/${delim}0/" |\
        sed "s/[[:space:]]*(After extra time).*$/${delim}1/" |\
        sed "s/PM${delim}/PM${delim}${delim}/" | sed "s/AM /AM${delim}${delim}/" |\
        sed "s/ (/${delim}/" | sed "s/M)/M/" |\
        sed "s/$year /${year}$delim/" |\
        sed "s|-Mar-|/03/|" |\
        sed "s|-Apr-|/04/|" |\
        sed "s|-May-|/05/|" |\
        sed "s|-Jun-|/06/|" |\
        sed "s|-Jul-|/07/|" |\
        sed "s|-Aug-|/08/|" |\
        sed "s|-Sep-|/09/|" |\
        sed "s|-Oct-|/09/|" |\
        sed "s|-Nov-|/10/|" |\
        sed "s/Mon /Mon$delim/" |\
        sed "s/Tue /Tue$delim/" |\
        sed "s/Wed /Wed$delim/" |\
        sed "s/Thu /Thu$delim/" |\
        sed "s/Fri /Fri$delim/" |\
        sed "s/Sat /Sat$delim/" |\
        sed "s/Sun /Sun$delim/" |\
        sed "s/^/${year}$delim/" \
        >> $csvMatchesYear
        
    echo "Convert delimiter to comma"
    sed -i '' "s/${delim}/,/g"  $csvMatchesYear
    sed -i '' "s/${delim}/,/g"  $csvTeamMatchesYear

    echo "Convert long team names to short ones"
    name2sname $csvMatchesYear
    name2sname $csvTeamMatchesYear

    cp $csvMatchesYear "$dirOut"
    cp "$csvTeamMatchesYear" "$dirOut"

    echo "Made '$dirOut/$csvMatchesYear'"
    echo "Made '$dirOut/$csvTeamMatchesYear'"

    cd ..
done

popd

$DEBUG || rm -rf "$dirTmp"
