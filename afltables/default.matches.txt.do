year=${2##*/}
html=matches/$year.matches.html
redo-ifchange $html
w3m -dump -cols 150 -T text/html $html > $3
