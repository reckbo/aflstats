cat playerteams.csv | cut -d, -f1 | \
while read team; do
    for year in `seq 2008 2015`; do
        echo $year-$team.players.csv
    done
done | xargs redo-ifchange -k

csvcat *.players.csv > $3
