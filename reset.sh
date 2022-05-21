# Prepare for measuring a new version.
#
# This should be executed after you have installed a new version of
# the extension and you want to start measuring that version.

# First, drop the extension and stop all workers
psql <<EOF
DROP EXTENSION IF EXISTS influx;

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE backend_type LIKE 'Influx%';
EOF

# Reinstall the extension and start a worker
psql <<EOF 
CREATE EXTENSION influx;
SELECT * FROM worker_launch('magic', '4711');
EOF

