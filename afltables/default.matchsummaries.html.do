year=${2##*/}
[ -f "$3" ] || curl http://afltables.com/afl/seas/$year.html > $3
