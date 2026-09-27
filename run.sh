#!/bin/sh

/usr/sbin/dovecot -F &

/run_cert_watcher.sh &

/run_cleanup.sh &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
