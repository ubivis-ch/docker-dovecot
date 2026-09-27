#!/bin/sh

while true; do
    inotifywait -qq -e modify $DOVECOT_SSL_CERTIFICATE
    echo "$(date) Public key updated, therefore reloading Dovecot config ..."
    sleep 1s
    kill -HUP $(cat /var/run/dovecot/master.pid)
done
