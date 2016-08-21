#!/bin/bash -eu

[ -f "$1" ] && { echo "'$1' already exists"; exit 0; }

sqlite3 $3 < makedb.sql 
