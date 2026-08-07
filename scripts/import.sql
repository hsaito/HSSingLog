
DROP VIEW IF EXISTS records_detail;
DROP VIEW IF EXISTS songs;
DROP TABLE IF EXISTS records;
DROP TABLE IF EXISTS tempo;
DROP TABLE IF EXISTS releases;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS titles;
DROP TABLE IF EXISTS records_with_titles;
DROP TABLE IF EXISTS records_csv;
DROP TABLE IF EXISTS titles_csv;
DROP TABLE IF EXISTS authors_csv;
DROP TABLE IF EXISTS release_csv;
DROP TABLE IF EXISTS tempo_csv;

CREATE TEMP TABLE titles_csv AS SELECT
  *
FROM read_csv('titles.csv',
  header=true,
  delim=',',
  quote='"',
  columns={
    "No.": 'UBIGINT',
    "Title ID": 'UUID',
    Title: 'VARCHAR',
    Artist: 'VARCHAR',
    ISWC: 'VARCHAR'
  });

CREATE TEMP TABLE authors_csv AS SELECT
  *
FROM read_csv('authors.csv',
  header=true,
  delim=',',
  quote='"',
  columns={
    "No.": 'UBIGINT',
    "Title ID": 'UUID',
    "Writer 1": 'VARCHAR',
    "Writer 2": 'VARCHAR',
    "Writer 3": 'VARCHAR',
    "Writer 4": 'VARCHAR',
    "Writer 5": 'VARCHAR',
    "Composer 1": 'VARCHAR',
    "Composer 2": 'VARCHAR',
    "Composer 3": 'VARCHAR',
    "Composer 4": 'VARCHAR',
    "Composer 5": 'VARCHAR',
    "Arranger 1": 'VARCHAR',
    "Arranger 2": 'VARCHAR',
    "Arranger 3": 'VARCHAR',
    "Arranger 4": 'VARCHAR',
    "Arranger 5": 'VARCHAR'
  });

CREATE TEMP TABLE release_csv AS SELECT
  *
FROM read_csv('release.csv',
  header=true,
  delim=',',
  quote='"',
  columns={
    "No.": 'UBIGINT',
    "Title ID": 'UUID',
    Year: 'INTEGER',
    Month: 'INTEGER',
    Day: 'INTEGER'
  });

CREATE TEMP TABLE tempo_csv AS SELECT
  *
FROM read_csv('tempo.csv',
  header=true,
  delim=',',
  quote='"',
  columns={
    "No.": 'UBIGINT',
    "Title ID": 'UUID',
    BPM: 'INTEGER',
    "BPM 01": 'INTEGER',
    "BPM 02": 'INTEGER',
    "BPM 03": 'INTEGER',
    "BPM 04": 'INTEGER',
    "BPM 05": 'INTEGER',
    "BPM 06": 'INTEGER',
    "BPM 07": 'INTEGER',
    "BPM 08": 'INTEGER',
    "BPM 09": 'INTEGER',
    "BPM 10": 'INTEGER'
  });

CREATE TEMP TABLE records_csv AS SELECT
  *,
  row_number() OVER () AS "Entry Number",
  strptime(regexp_extract(filename, '([0-9]{8})', 1), '%Y%m%d')::DATE AS "Session Date",
  CAST(NULLIF(regexp_extract(filename, '-([0-9]+)', 1), '') AS INT) AS "Session Number"
FROM read_csv('HSSingLog*.csv',
  header=true,
  delim=',',
  quote='"',
  filename=true,
  columns={
    "Sequence": 'UBIGINT',
    "Entry ID": 'UUID',
    "Title ID": 'UUID',
    Title: 'VARCHAR',
    Artist: 'VARCHAR',
    Score: 'FLOAT',
    Platform: 'VARCHAR',
    Tone: 'FLOAT',
    Stability: 'FLOAT',
    Intonation: 'FLOAT',
    "Long Tone": 'FLOAT',
    Technique: 'FLOAT',
    "Guide Melody": 'VARCHAR',
    Shakuri: 'UINTEGER',
    Tremolo: 'UINTEGER',
    Vibrato: 'UINTEGER',
    Note: 'VARCHAR'
  });

CREATE TABLE titles (
  "Title ID" UUID PRIMARY KEY,
  Title VARCHAR NOT NULL,
  Artist VARCHAR NOT NULL,
  ISWC VARCHAR
);

CREATE TABLE authors (
  "Title ID" UUID PRIMARY KEY REFERENCES titles("Title ID"),
  Writers VARCHAR[],
  Composers VARCHAR[],
  Arrangers VARCHAR[]
);

CREATE TABLE releases (
  "Title ID" UUID PRIMARY KEY REFERENCES titles("Title ID"),
  Year INTEGER,
  Month INTEGER,
  Day INTEGER,
  "Release Date" DATE
);

CREATE TABLE tempo (
  "Title ID" UUID PRIMARY KEY REFERENCES titles("Title ID"),
  Tempo INTEGER,
  Tempos INTEGER[]
);

CREATE TABLE records (
    "Entry Number" UBIGINT,
    "Session Sequence" UBIGINT,
    "Entry ID" UUID UNIQUE PRIMARY KEY,
    "Title ID" UUID NOT NULL REFERENCES titles("Title ID"),
    "Session Date" DATE NOT NULL,
    "Session Number" INT,
  Title VARCHAR NOT NULL,
  Artist VARCHAR NOT NULL,
    Score FLOAT NOT NULL,
    Platform VARCHAR NOT NULL,
    Tone FLOAT,
    Stability FLOAT,
    Intonation FLOAT,
    "Long Tone" FLOAT,
    Technique FLOAT,
    "Guide Melody" VARCHAR,
    Shakuri UINTEGER,
    Tremolo UINTEGER,
    Vibrato UINTEGER,
    Note VARCHAR
);

INSERT INTO titles
SELECT
  "Title ID",
  Title,
  Artist,
  ISWC
FROM titles_csv;

INSERT INTO authors
SELECT
  "Title ID",
  list_filter(list_value("Writer 1", "Writer 2", "Writer 3", "Writer 4", "Writer 5"), lambda writer: writer IS NOT NULL),
  list_filter(list_value("Composer 1", "Composer 2", "Composer 3", "Composer 4", "Composer 5"), lambda composer: composer IS NOT NULL),
  list_filter(list_value("Arranger 1", "Arranger 2", "Arranger 3", "Arranger 4", "Arranger 5"), lambda arranger: arranger IS NOT NULL)
FROM authors_csv;

INSERT INTO releases
SELECT
  "Title ID",
  Year,
  Month,
  Day,
  CASE
    WHEN Year IS NOT NULL AND Month IS NOT NULL AND Day IS NOT NULL THEN try_strptime(printf('%04d-%02d-%02d', Year, Month, Day), '%Y-%m-%d')::DATE
    ELSE NULL
  END AS "Release Date"
FROM release_csv;

INSERT INTO tempo
SELECT
  "Title ID",
  BPM AS Tempo,
  list_filter(list_value("BPM 01", "BPM 02", "BPM 03", "BPM 04", "BPM 05", "BPM 06", "BPM 07", "BPM 08", "BPM 09", "BPM 10"), lambda tempo_value: tempo_value IS NOT NULL) AS Tempos
FROM tempo_csv;

INSERT INTO records
SELECT
  rc."Entry Number",
  rc."Sequence" AS "Session Sequence",
  rc."Entry ID",
  rc."Title ID",
  rc."Session Date",
  rc."Session Number",
  t.Title,
  t.Artist,
  rc.Score,
  rc.Platform,
  rc.Tone,
  rc.Stability,
  rc.Intonation,
  rc."Long Tone",
  rc.Technique,
  rc."Guide Melody",
  rc.Shakuri,
  rc.Tremolo,
  rc.Vibrato,
  rc.Note
FROM records_csv rc
JOIN titles t USING ("Title ID");

CREATE VIEW songs AS
SELECT
  t."Title ID",
  t.Title,
  t.Artist,
  t.ISWC,
  a.Writers,
  a.Composers,
  a.Arrangers,
  r.Year,
  r.Month,
  r.Day,
  r."Release Date",
  tp.Tempo,
  tp.Tempos
FROM titles t
LEFT JOIN authors a USING ("Title ID")
LEFT JOIN releases r USING ("Title ID")
LEFT JOIN tempo tp USING ("Title ID");

CREATE VIEW records_detail AS
SELECT
  rc."Entry Number",
  rc."Session Sequence",
  rc."Entry ID",
  rc."Title ID",
  rc."Session Date",
  rc."Session Number",
  rc.Title,
  rc.Artist,
  rc.Score,
  rc.Platform,
  rc.Tone,
  rc.Stability,
  rc.Intonation,
  rc."Long Tone",
  rc.Technique,
  rc."Guide Melody",
  rc.Shakuri,
  rc.Tremolo,
  rc.Vibrato,
  rc.Note,
  s.ISWC,
  s.Writers,
  s.Composers,
  s.Arrangers,
  s.Year AS "Release Year",
  s.Month AS "Release Month",
  s.Day AS "Release Day",
  s."Release Date",
  s.Tempo,
  s.Tempos
FROM records rc
LEFT JOIN songs s USING ("Title ID");

DROP TABLE IF EXISTS records_csv;
DROP TABLE IF EXISTS titles_csv;
DROP TABLE IF EXISTS authors_csv;
DROP TABLE IF EXISTS release_csv;
DROP TABLE IF EXISTS tempo_csv;