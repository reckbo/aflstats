#!/bin/bash -eu

year=2014
srcdir=html
outdir=matches
matchescsv=$year-matches.csv
teammatchescsv=$year-matches-team.csv

html=$(readlink -m "$srcdir/$year.html")
[ -f $html ] || curl http://afltables.com/afl/seas/$year.html > $html

tmp=$(mktemp -d)
echo "Working in temp dir: $tmp"
pushd $tmp >/dev/null

# render html as text
txt=$year.txt
cat $html | w3m -dump -cols 150 -T text/html > $txt

# Split text file into rounds
cat $txt | grep -E 'Round |won by|Match drawn|Venue|Preliminary Final|Semi Final|Elimination Final|Qualifying Final|Grand Final' | \
    gcsplit -f xx -  '/Round \|Final/' '{*}' > /dev/null

# Extract info from each round

#cat $txtfile | sed 1d | cut -c 2- | tr '│' ','  | cut -d, -f1-4 > $outfile
mkdir -p rounds
for xx in xx*; do
    roundid=$(echo $xx | cut -c 3-)
    echo "=== Round $roundid"

    # clean w3m characters
    cat $xx | tr '│' '|' | tr '┃' '|' | cut -c 2- > $xx
    [[ $xx != xx00 ]] || continue

    # make filename from round's heading
    heading=$(sed -n 1p "$xx" | cut -d'|' -f1 | tr -d '[[:space:]]')
    csv="$year-$roundid-$heading.csv"

    # save clean data to file
    echo "Make '$csv' from '$xx'"
    sed 1d $xx | cut -d'|' -f1-4 > $csv

    # if a season round, split into individual games
    if [[ $roundid < 24 ]]; then
        echo "Split '$csv' into individual games"
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

echo "Extract game info to make game row in each csv"
for csv in *.csv; do
    gameid=$(echo $csv | cut -d. -f1)
    ftmp=$(mktemp)
    #echo "ftmp $ftmp"
    cat $csv | cut -d'|' -f 4 | tr '\n' '|' | sed s'/\[Match stats\]//g' > $ftmp
    cat $csv | cut -d'|' -f 1-3 >> $ftmp
    sed "s/^/$gameid\|/" $ftmp | sed 's/[[:space:]]*|/|/g' | sed 's/|[[:space:]]*/|/g' > $csv
    rm $ftmp
done

popd >/dev/null

mkdir -p $outdir
ls $tmp/*.csv | xargs -n 1 sed -n 1p > $outdir/$matchescsv
ls $tmp/*.csv | xargs -n 1 sed 1d > $outdir/$teammatchescsv
rm -rf $tmp
echo "Made '$outdir/$matchescsv'"
echo "Made '$outdir/$teammatchescsv'"
