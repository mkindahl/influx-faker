#!/bin/bash

# Generate fake data and send it to the started worker thread. It will
# then collect data on how many that actually made it, since this is
# UDP packets will be dropped if they are not processed fast enough.

function usage() {
    if [[ $# -gt 0 ]]; then
	echo "error: $*" 1>&2
    fi
    cat <<EOF 1>&2
Usage: bash collect.sh [ -s <scheme> ]
Collect measurements for scheme.

This will generate fake data and send it to the started worker thread
(see script setup.sql). It will then collect data on how many that
actually made it, since this is UDP packets will be dropped if they
are not processed fast enough.

The measurements will be stored under version of the extension plus
scheme name. If no version is provided, no version argument will be
provided when installing the extension, so the default version will be
installed.

Options

    -s <scheme>    Use the provided scheme
    -p <port>      Connect to the port
    -v <version>   Version of extension to use
    -w <workers>   Number of workers to spawn

EOF
    exit 2
}

function reset_extension () {
    # First, drop the extension and stop all workers
    psql -q <<EOF
DROP EXTENSION IF EXISTS influx;

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE backend_type LIKE 'Influx%';
EOF

    # Reinstall the extension and start a worker. Pick a specific
    # version if one is set.
    if [[ -z "$VERSION" ]]; then
	psql -q -c "CREATE EXTENSION influx"
    else
	psql -q -c "CREATE EXTENSION influx VERSION '$VERSION'"
    fi
    for _ in $(seq 1 "$WORKERS"); do
	psql -q -c "SELECT * FROM worker_launch('magic', '$PORT');"
    done
}

function show_measurements () {
    psql -q <<EOF
SELECT version, scheme, total, count(*), avg(count::decimal), stddev(count)
  FROM measurements GROUP BY version, scheme, total
EOF
}

# Default values for variables. Note that the PGXXX variables are for
# psql, but these variables are for other purposes.
HOST=${PGHOST:-localhost}
PORT=8089
WORKERS=1
SCHEME=basic
REPEATS=${REPEATS:-100}

set -e

while getopts "h:p:s:v:w:" opt; do
    case $opt in
	h)
	    HOST=$OPTARG
	    ;;
	p)
	    PORT=$OPTARG
	    ;;
	s)
	    SCHEME=$OPTARG
	    ;;
	v)
	    VERSION=$OPTARG
	    ;;
	w)
	    WORKERS=$OPTARG
	    ;;
	*)
	    usage
	    ;;
    esac
done

if [[ -z "$SCHEME" ]]; then
    usage "You need to provide a scheme to use"
elif ! [[ -r "scheme/$SCHEME.sh" ]]; then
    usage "You need to have a file scheme/$SCHEME.sh containing the scheme"
fi

if [[ -z "$PORT" ]]; then
    usage "You need to provide a port to use"
fi

# Each scheme is in a file with functions to handle each primitive
# action.
#
# setup_schema:
#    Create the initial schema and tables to receive the data
#
# reset_schema:
#    Reset the schema and tables to prepare for a run.
#
# wait_until_stable:
#    Wait for the processing to stabilize
#
# record_measurements:
#    Record measurements from the tables
#
# The following environment variables are set up for use in the
# functions:
#
# VERSION:
#    Extension version
#
# SCHEME:
#    Name of the scheme. The name of the file, for now.
#
# COUNT:
#    Number of rows sent to the port.

echo "Connecting to $HOST and using $PORT as listen port"

# shellcheck source=scheme/basic.sh
source "scheme/$SCHEME.sh"

set -e

function influx_version() {
    # Use echo here to get rid of surrounding whitespace
    echo $(psql -qt -c "select extversion from pg_extension where extname = 'influx'")
}

# Need to set up the scheme first, since that decides what schema to use.
setup_scheme
reset_extension

VERSION=$(influx_version)

echo "Measure ${COUNT:=1000000} lines for version '$VERSION' scheme $SCHEME"

while true; do
    reset_scheme
    cargo run -q "$HOST:$PORT" "$COUNT"

    # Since the lines are processed in the background, we can still be
    # processing lines even though we have stopped sending then.
    #
    wait_until_stable
    record_measurements
    show_measurements
    # If we have a $REPEATS measurements, we can stop.
    count=$(psql -qt -c "SELECT count(*) FROM measurements WHERE version = '$VERSION' AND scheme = '$SCHEME'")
    if [ "$count" -ge "$REPEATS" ]; then
	break
    fi
done
