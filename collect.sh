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
scheme name.

Options

    -s <scheme>    Use the provided scheme
    -p <port>      Connect to the port

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
    psql -q -c "SELECT * FROM worker_launch('magic', '$PORT');"
}

function show_measurements () {
    psql -q <<EOF
SELECT version, scheme, total, count(*), avg(count::decimal), stddev(count)
  FROM measurements GROUP BY version, scheme, total
EOF
}

SCHEME=basic

set -e

while getopts "p:s:v:" opt; do
    case $opt in
	p)
	    PORT=$OPTARG
	    ;;
	s)
	    SCHEME=$OPTARG
	    ;;
	v)
	    VERSION=$OPTARG
	    ;;
	*)
	    usage
	    ;;
    esac
done

reset_extension

VERSION=$(echo $(psql -t -c "select extversion from pg_extension where extname = 'influx'"))

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

echo "Measure ${COUNT:=1000000} lines for version '$VERSION' scheme $SCHEME"
echo "Connecting to $PGHOST and using $PORT as listen port"

source scheme/$SCHEME.sh

set -e

setup_scheme
while true; do
    reset_scheme
    cargo run -q $PGHOST:$PORT $COUNT

    # Since the lines are processed in the background, we can still be
    # processing lines even though we have stopped sending then.
    #
    wait_until_stable
    record_measurements
    show_measurements
    # If we have a 100 measurements, we can stop.
    count=$(psql -t -c "SELECT count(*) FROM measurements WHERE version = '$VERSION' AND scheme = '$SCHEME'")
    if [ $count -ge 100 ]; then
	break
    fi
done
