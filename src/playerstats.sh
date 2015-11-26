#!/bin/bash -eu
#
# Scrapes afltables.com team player pages 
#
# Dependencies
# * curl
# * elinks
# * GNU csplit (runs gcsplit if it's found)
# * sed
# * tr
#
# Output
#   out-playerstats/year/team/*.tsv

csplit() {
    if hash gcsplit 2>/dev/null; then
        gcsplit "$@"
    else
        csplit "$@"
    fi
}


# Input
teams="padelaide \
collingwood \
fremantle \
essendon \
geelong \
goldcoast \
gws \
hawthorn \
kangaroos \
richmond \
stkilda \
westcoast \
bullldogs"

years=$(seq 1990 2015)

if [ "${1-}" ]; then
    years=$@
fi

# Output
dirHtml=out-html
mkdir $dirHtml &>/dev/null || true

for year in $years; do
    for team in $teams; do
        echo "== $year $team =="

        # Set output paths
        html=$(readlink -m "$dirHtml/${team}_${year}_gbg.html")
        dirOut="out-playerstats/$year/$team"

        # Download html page if not done so already
        url=http://afltables.com/afl/stats/teams/${team}/${year}_gbg.html
        [ -f "$html" ] || curl $url > $html 

        # Make and change to temporary directory
        dirTmp=$(mktemp -d)
        echo "Working in temp dir: $dirTmp"
        pushd $dirTmp >/dev/null

        # Render html to text
        txt=${team}_${year}.txt
        echo "Render the html page text: $html --> $txt"
        #cat $html | w3m -dump -cols 190 -T text/html -o display_charset=UTF-8 > $txt
        cat $html | sed 's/<a[^>]*>//g' | sed 's/<\/a>//g' | elinks -dump -dump-width 250 > $txt

        # Check if it's valid stats page (some years are missing for some teams)
        if grep "This page has been sent off" "$txt" &>/dev/null; then
            echo "No data for $team in $year"
            popd
            continue
        fi

        # Remove extraneous lines and spaces
        txtCleaned=${team}_${year}_cleaned.txt
        echo "Clean the text file: $txt --> $txtCleaned"
        grep '|' $txt | grep -v '\-\+\-' | sed 's,[[:space:]]*|,|,g' | sed 's,|[[:space:]]*,|,g' > $txtCleaned

        # Split table into sections
        dirTxt=txt
        echo "Split the table into sections: $txtCleaned --> $dirTxt/xx*"
        mkdir $dirTxt &>/dev/null || true
        cat $txtCleaned | csplit -f $dirTxt/xx - '/Disposals\|Kicks\|Marks\|Handballs\|Goals\|Behinds\|Hit Outs\|Tackles\|Rebounds\|Inside 50s\|Clearances\|Clangers\|Frees\|Frees Against\|Brownlow Votes\|Possessions\|Uncontested\|Contested\|Marks Inside 50\|One Percenters\|Bounces\|Goal Assists\|% Played\|Subs/' '{*}' &>/dev/null
        rm $dirTxt/xx00

        # Remove first line and make it the file's name (name of the stat, e.g. marks, goals, handballs)
        delim='\t'
        dirTsv=$dirTmp/tsv
        mkdir $dirTsv &> /dev/null || true 
        for xx in $dirTxt/xx*; do
            tmp=$dirTsv/tmp
            cat $xx | sed "s/^|//g" | sed "s/|$//g"  > $tmp
            #stat=$(sed -n 1p $tmp | sed "s/[[:space:]]*|[[:space:]]*//g" | sed "s/[[:space:]]/_/g" | sed "s/|//g")
            statname=$(sed -n 1p $tmp | sed "s/[[:space:]]/_/g")
            tsvOut=$dirTsv/${statname}.tsv
            sed 1d $tmp | tr '|' "$delim" | sed "s/^$delim//" > $tsvOut
            rm $tmp
            echo "Made '$tsvOut'"
        done

        popd >/dev/null

        # make output directory with final stat tsv's
        mkdir -p "$dirOut" || true
        echo "Copying to '$dirOut'"
        cp "$dirTsv"/* "$dirOut"

        # clean up
        echo "Deleting temp directory '$dirTmp'"
        rm -rf "$dirTmp"

        echo "Done."
    done
done
