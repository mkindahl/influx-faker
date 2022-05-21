-- Set up the tables in the magic schema and create the measurements
-- table and a view to measure the total number of rows inserted.
CREATE SCHEMA magic;
CREATE TABLE IF NOT EXISTS magic.cpu (
    _time timestamptz,
    _tags jsonb,
    _fields jsonb
);
CREATE TABLE IF NOT EXISTS magic.swap (LIKE magic.cpu);
CREATE TABLE IF NOT EXISTS magic.disk (LIKE magic.cpu);
CREATE TABLE IF NOT EXISTS magic.diskio (LIKE magic.cpu);

DROP VIEW IF EXISTS combined;
CREATE VIEW combined AS
    SELECT _time, _tags, _fields FROM magic.cpu
  UNION ALL
    SELECT _time, _tags, _fields FROM magic.swap
  UNION ALL
    SELECT _time, _tags, _fields FROM magic.disk
  UNION ALL
    SELECT _time, _tags, _fields FROM magic.diskio;

CREATE TABLE IF NOT EXISTS measurements (
   time timestamptz,
   version text,
   count int,
   total int 
);
