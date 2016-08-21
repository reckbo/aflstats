CREATE TABLE match(
  round TEXT,
  team TEXT,
  progression TEXT,
  score INTEGER,
  winner TEXT,
  opponent TEXT,
  venue TEXT,
  attendance INTEGER,
  year INTEGER,
  date TEXT,
  id TEXT NOT NULL
);
CREATE TABLE playerT(
  year INTEGER,
  team TEXT,
  name TEXT,
  round TEXT,
  KI INTEGER,
  MK INTEGER,
  HB INTEGER,
  FA INTEGER,
  FF INTEGER,
  TK INTEGER,
  GL INTEGER,
  HO INTEGER,
  BH INTEGER,
  pctP INTEGER
);
CREATE TABLE player(
  name TEXT,
  matchid TEXT NOT NULL,
  KI INTEGER,
  MK INTEGER,
  HB INTEGER,
  FA INTEGER,
  FF INTEGER,
  TK INTEGER,
  GL INTEGER,
  HO INTEGER,
  BH INTEGER,
  pctP INTEGER,
  FOREIGN KEY (matchid) REFERENCES match(id)
);
CREATE TABLE team(
  urlname TEXT NOT NULL,
  name TEXT NOT NULL
);

.mode csv
-- populate team
.import players/playerteams.csv team

-- populate match
.import matches.csv match

-- populate playerT
.shell sed 1d players/players.csv > /tmp/t.csv
.headers on
.import /tmp/t.csv playerT

-- make player
CREATE TABLE playerTT as
  SELECT p.name,year,round,KI,MK,HB,FA,FF,TK,GL,HO,BH,pctP,t.name as teamname
    FROM playerT as p
    LEFT JOIN team as t
    ON p.team=t.urlname;

INSERT INTO player
  select name,match.id as matchid,KI,MK,HB,FA,FF,TK,GL,HO,BH,pctP
    from playerTT
    left join match
      on match.year=playerTT.year
      and match.round=playerTT.round
      and match.team=playerTT.teamname;

drop table playerT;
drop table playerTT;
