#!/bin/bash

# Generate fake data and send it to the started worker thread. It will
# then collect data on how many that actually made it, since this is
# UDP packets will be dropped if they are not processed fast enough.

function usage() {
    cat <<EOF 1>&2
Usage: bash collect.sh [ -s <scheme> ]
Collect measurements for scheme.

This will generate fake data and send it to the started worker thread
(see script setup.sql). It will then collect data on how many that
actually made it, since this is UDP packets will be dropped if they
are not processed fast enough.

The measurements will be stored under version of the extension plus
scheme name.
EOF
    exit 2
}

VERSION=$(echo $(psql -t -c "select extversion from pg_extension where extname = 'influx'"))
SCHEME=basic

while getopts "t:" opt; do
    case $opt in
	s)
	    SCHEME=$OPTARG
	    ;;
	*)
	    usage
	    ;;
    esac
done

if [[ -z "$SCHEME" ]]; then
    echo "You need to provide a scheme to use" 1>&2
    exit 2
elif ! [[ -r "scheme/$SCHEME.sh" ]]; then
    echo "You need to have a file $SCHEME.sh containing the scheme" 1>&2
    exit 2
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

source scheme/$SCHEME.sh

set -e

function show_measurements () {
    psql -q <<EOF
SELECT version, scheme, total, count(*), avg(count::decimal), stddev(count)
  FROM measurements GROUP BY version, scheme, total
EOF
}

setup_scheme
while true; do
    reset_scheme
    cargo run -q 127.0.0.1:4711 $COUNT

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
