# Generate fake data and send it to the started worker thread. It will
# then collect data on how many that actually made it, since this is
# UDP packets will be dropped if they are not processed fast enough.
VERSION=$(echo $(psql -t -c "select extversion from pg_extension where extname = 'influx'"))
echo "Measure ${COUNT:=1000000} lines for version '$VERSION'"
while true; do
    psql -q -c 'TRUNCATE magic.swap, magic.cpu, magic.disk, magic.diskio'
    cargo run -q 127.0.0.1:4711 $COUNT

    # Since the lines are processed in the background, we can still be
    # processing lines even though we have stopped sending then.
    #
    # Wait until the count is stable. Then all lines should have been
    # processed. We start at -1 since a very fast check might give
    # zero back.
    echo -n "Waiting.."
    prev=-1
    while true; do
	cnt=$(psql -t -c "SELECT count(*) FROM combined")
	if [ $cnt -eq $prev ]; then
	    break
	fi
	prev=$cnt
	echo -n "."
	sleep 1
    done
    echo "stable (at $(echo $cnt))"
    psql -q -c "INSERT INTO measurements(time, count, total, version) SELECT now(), count(*), $COUNT, '$VERSION' FROM combined"
    psql -c 'SELECT version, count(*), avg(count::decimal), stddev(count) FROM measurements GROUP BY version, total'

    # If we have a 100 measurements, we can stop.
    count=$(psql -t -c "SELECT count(*) FROM measurements WHERE version = '$VERSION'")
    if [ $count -ge 100 ]; then
	break
    fi
done
