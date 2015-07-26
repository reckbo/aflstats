#!/bin/bash -eu

srcdir=html
outdir=matches
mcsv=$outdir/matches.csv
mpcsv=$outdir/matches-player.csv
delim="|"
DEBUG=false

# get list of input html's
for arg in $@; do
    [[ "$arg" != "-d" ]] || { DEBUG=true; continue; }
    years=$arg
done
[ -n "${years-}" ] || years=$(ls $srcdir/*.html | xargs basename | cut -d. -f1)

# clear output directory
rm -rf $outdir/*.csv || true 

# make staging area
staging=$(mktemp -d)
echo "Made staging directory: $staging"

# for each html
echo "$years"
for year in $years; do
    # csv names for each year
    matchescsv=$year-matches.csv
    teammatchescsv=$year-matches-team.csv

    # get html from website if missing
    html=$(readlink -m "$srcdir/$year.html")
    [ -f $html ] || curl http://afltables.com/afl/seas/$year.html > $html

    # change to temporary directory
    tmp=$(mktemp -d)
    echo "Working in temp dir: $tmp"
    pushd $tmp >/dev/null

    # render html as text
    cat $html | w3m -dump -cols 150 -T text/html > $year.txt

    # Split text file into AFL rounds
    cat $year.txt | grep -E 'Round |won by|Match drawn|Venue|Preliminary Final|Semi Final|Elimination Final|Qualifying Final|Grand Final' | \
        gcsplit -f xx -  '/Round \|Final/' '{*}' > /dev/null

    # for each round, make a csv for each match
    mkdir -p rounds
    for xx in xx*; do
        roundid=$(echo $xx | cut -c 3-)
        echo "=== Round $roundid"

        # clean w3m characters by converting to commas
        cat $xx | tr '│' "$delim" | tr '┃' "$delim" | cut -c 2- > $xx
        [[ $xx != xx00 ]] || continue  # first section is empty

        # make filename/matchid using round's heading
        heading=$(sed -n 1p "$xx" | cut -d"$delim" -f1 | tr -d '[[:space:]]')
        csv="$year-$roundid-$heading.csv"

        # save clean data to file
        echo "Make '$csv' from '$xx'"
        sed 1d $xx | cut -d"$delim" -f1-4 > $csv

        # if a regular season round, split into individual matches
        if  echo $heading | grep -q "Round" ; then
            echo "Split '$csv' into individual matches"

            # Completed rounds only
            if ! grep -Eq 'won by|drawn' $csv; then { echo "No matches yet, skipping"; mv $csv rounds/; continue; } fi

            # Sanity check - round should have even number of entries 
            evencheck="$(wc -l < $csv | tr -d '[[:space:]]') % 2" 
            [[ $(echo $evencheck | bc) = 0 ]] || { echo "'$csv' doesn't have even number of entries"; exit; }

            # Split round
            pre="$year-$roundid-"
            gsplit -d --lines 2 --additional-suffix ".csv" $csv $pre

            # Move original
            mv $csv rounds/
        fi
    done

    # For each match csv, make a match info row
    echo "Extract match info to make match row in each csv"
    for csv in *.csv; do
        gameid=$(echo $csv | cut -d. -f1)
        ftmp=$(mktemp)
        cat $csv | cut -d"$delim" -f 4 | tr '\n' "$delim" | sed s'/\[Match stats\]//g' > $ftmp
        cat $csv | cut -d"$delim" -f 1-3 >> $ftmp
        sed "s/^/$gameid$delim/" $ftmp |\
            sed "s/[[:space:]]*$delim/$delim/g" |\
            sed "s/$delim[[:space:]]*/$delim/g" |\
            sed "s/$delim$//" |\
            sed 's/\([0-9]\),\([0-9]\)/\1\2/g' > $csv
        rm $ftmp
    done

    # Move the year's match csv's to staging
    popd >/dev/null
    mkdir -p $outdir
    ls $tmp/*.csv | xargs -n 1 sed -n 1p > $staging/$matchescsv
    ls $tmp/*.csv | xargs -n 1 sed 1d > $staging/$teammatchescsv
    $DEBUG || rm -rf $tmp
    echo "Made '$outdir/$matchescsv'"
    echo "Made '$outdir/$teammatchescsv'"
done

# Merge each match's 2 player rows into one csv
echo "matchid${delim}team${delim}score_progression${delim}score" > $mpcsv
cat $staging/*-matches-team.csv  |\
    sed "s/[[:space:]]*${delim}/${delim}/g" |\
    sed "s/${delim}[[:space:]]*/${delim}/g" \
    >> $mpcsv

# Merge each match csv's match info row into one csv, and
# make new columns: venue, attendance, winning team, won by
echo "matchid${delim}date${delim}attendance${delim}venue${delim}winner${delim}won_by" > $mcsv
cat $staging/*-matches.csv | \
    sed "s/Att:/${delim}/" | \
    sed "s/Venue: /${delim}/" | \
    sed "s/ won by /${delim}/" | \
    sed 's/ pts//' |\
    sed 's/ pt//' |\
    sed "s/Match drawn/NA${delim}0/" |\
    sed "s/Venue: /${delim}/" |\
    sed "s/[[:space:]]*${delim}/${delim}/g" |\
    sed "s/${delim}[[:space:]]*/${delim}/g" \
    >> $mcsv
    
# convert delimter to comma
sed -i '' "s/${delim}/,/g"  $mcsv
sed -i '' "s/${delim}/,/g"  $mpcsv

name2sname() {
    sed 1d teams.csv | while IFS=, read sname name; do
        sed -i '' "s/${name}/${sname}/g" $1
    done
}
name2sname $mcsv
name2sname $mpcsv

$DEBUG || rm -rf "$staging"

echo "Made '$mcsv'"
echo "Made '$mpcsv'"
