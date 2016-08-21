while read team; do
    for year in `seq 2008 2015`; do
        echo $year-$team.playerstats.csv
    done
done < playerstatsteams.txt | xargs redo-ifchange -k

csvcat *.playerstats.csv > $3
