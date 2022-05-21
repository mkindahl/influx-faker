# Fake InfluxDB Protocol

Package to generate InfluxDB Line Protocol and send it over network.

UDP is a lossy protocol, meaning that any packets not processed fast
enough will be dropped. This means that we can measure performance by
sending lines to the receiver as fast as possible and just see how
many are actually added to the tables. As long as the system does not
process all lines, we can compare performance of different
deployments.

This package contains a faker that sends fake data to a UDP port and
also tools to measure the performance by seeing how many packets are
actually processed.

## Running the tests

1. Setup the database
2. Prepare for execution
3. Generate measurements

To setup the database run the script `setup.sql` on the server. Make
sure to set `PGDATA` to the right path for the server (or use option
`-d` for `psql`) and that `psql` is in the path.

```bash
PATH=/usr/local/postgresql/13.5/bin:$PATH
PGDATA=/var/lib/pgsql/13/data
psql -f setup.sql
```

After that, prepare for execution of one version by running the script
`reset.sh`. This is done once after installing the `influx` package
you want to check. This will:

1. Remove the old extension
2. Terminate all Influx backends
3. Reinstall the Influx package (with the default version)
4. Start a worker listening on port 4711 and writing to schema `magic`

You can now run the collection of data using `collect.sh`, which is
taking 100 samples of of the run in the following manner:
1. Fetch the version of the extension
2. Truncate the tables in schema `magic`
3. Run the generator to write to port 4711 on localhost using UDP
4. Wait for the count to be stable, indicating that the worker is done
   processing the lines.
5. Insert version, timestamp, a total count of rows, and the number of
   rows sent into the table `public.measurements`.
6. Repeat steps 2-5 until there are 100 measurements.

If you stop the script, it will leave existing measurements in the
table and just fill up until the count is 100.

## Plotting data

To plot the data using R, you can install these packages on Ubuntu:

    sudo apt install r-base-core r-cran-ggplot2 r-cran-rpostgresql

Script for doing a violin plot is then:

```R
library('RPostgreSQL')
library(ggplot2)

pg = dbDriver("PostgreSQL")
con = dbConnect(pg, dbname="mats", host="localhost", port=5432)
table = dbGetQuery(con, "SELECT * FROM measurements")
ggplot(table, aes(x=version, y=count, fill=version)) + geom_violin()
```

