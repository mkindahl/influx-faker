#!/bin/bash

function setup_scheme () {
    psql -q <<EOF
CREATE SCHEMA IF NOT EXISTS magic;

DROP VIEW IF EXISTS combined;
DROP TABLE IF EXISTS magic.cpu;
DROP TABLE IF EXISTS magic.disk;
DROP TABLE IF EXISTS magic.swap;
DROP TABLE IF EXISTS magic.diskio;

CREATE TABLE magic.cpu (
    _time timestamptz,
    _tags jsonb,
    _fields jsonb
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
EOF
}

function reset_scheme () {
    psql -q -c 'TRUNCATE magic.swap, magic.cpu, magic.disk, magic.diskio'
}

# Wait until the count is stable.
#
# Then all lines should have been processed. We start at -1 since a
# very fast check might give zero back.
function wait_until_stable () {
    echo -n "Waiting.."
    prev=-1
    while true; do
	cnt=$(psql -qt -c "SELECT count(*) FROM combined")
	if [[ "$cnt" -eq "$prev" ]]; then
	    break
	fi
	prev=$cnt
	echo -n "."
	sleep 1
    done
    echo "stable (at $cnt)"
}

function record_measurements () {
    psql -q <<EOF
INSERT INTO measurements(time, count, total, version, scheme)
SELECT now(), count(*), $COUNT, '$VERSION', '$SCHEME' FROM combined
EOF
}
