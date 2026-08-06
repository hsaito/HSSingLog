.read scripts/import.sql

EXPORT DATABASE 'parquet' (FORMAT PARQUET);
