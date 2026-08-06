



CREATE TABLE records_csv AS SELECT
  *,
  row_number() OVER () AS "Entry Number",
  strptime(regexp_extract(filename, '([0-9]{8})', 1), '%Y%m%d')::date AS "Session Date",
  -- ハイフンの後の数字を抽出（拡張子は無視）
  CAST(NULLIF(regexp_extract(filename, '-([0-9]+)', 1), '') AS INT) AS "Session Number"
FROM read_csv('HSSingLog*.csv', 
  header=true, 
  delim=',', 
  quote='"', 
  columns={
    "Sequence": 'UBIGINT',
    "Entry ID": 'GUID',
    "Title ID": 'GUID',
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
    Note: 'VARCHAR',
  });

CREATE TABLE records (
    "Entry Number" UBIGINT,
    "Session Sequence" UBIGINT,
    "Entry ID" GUID UNIQUE PRIMARY KEY,
    "Title ID" GUID NOT NULL,
    "Session Date" DATE NOT NULL,
    "Session Number" INT,
    Title VARCHAR NOT NULL,
    Artist VARCHAR,
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

INSERT INTO records
SELECT
  "Entry Number",
  "Sequence" AS "Session Sequence",
  "Entry ID",
  "Title ID",
  "Session Date",
  "Session Number",
  Title,
  Artist,
  Score,
  Platform,
  Tone,
  Stability,
  Intonation,
  "Long Tone",
  Technique,
  "Guide Melody",
  Shakuri,
  Tremolo,
  Vibrato,
  Note
  FROM records_csv;