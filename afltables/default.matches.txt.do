year=${2##*/}
html=$year/$year.matchsummaries.html
redo-ifchange $html
w3m -dump -cols 150 -T text/html $html > $3
