Html scraper for afltables.com.

The Bash scripts require
* curl
* w3m (renders html as text)
* elinks (renders html as text)
* GNU csplit (gcsplit)
* GNU split (gsplit)

# Run

    cd src
    ./mathstats.sh
    ./playerstats.sh

The scripts save the html pages to `out-html`, and save their csv files to
`out-matchstats` and `out-playerstats`.  You can see the results in `data/`.

