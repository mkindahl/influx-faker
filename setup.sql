-- Set up the tables in the magic schema and create the measurements
-- table and a view to measure the total number of rows inserted.
CREATE SCHEMA magic;

DROP VIEW IF EXISTS combined;
DROP TABLE IF EXISTS magic.cpu;
DROP TABLE IF EXISTS magic.disk;
DROP TABLE IF EXISTS magic.swap;
DROP TABLE IF EXISTS magic.diskio;

CREATE TABLE magic.cpu (
    _time timestamptz,
    cpu text,
    host text
);

CREATE TABLE magic.swap (
    _time timestamptz,
    _tags jsonb,
    _fields jsonb
);

CREATE TABLE magic.disk (
    _time timestamptz,
    _tags jsonb,
    _fields jsonb
);

CREATE TABLE magic.diskio (
    _time timestamptz,
    _tags jsonb,
    _fields jsonb
);

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
