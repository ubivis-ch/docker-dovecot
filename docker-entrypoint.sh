#!/bin/sh

echo -n "
# Config override ...
!include auth-ldap.conf.ext
" >> /etc/dovecot/conf.d/10-auth.conf


echo -n "
# Config override ...
mail_location = maildir:/home/vmail/%d/%n/Maildir
mail_uid = vmail
mail_gid = vmail
" >> /etc/dovecot/conf.d/10-mail.conf


echo -n "
# Config override ...
log_path = /dev/stderr
info_log_path = /dev/stdout
" >> /etc/dovecot/conf.d/10-logging.conf


echo -n "
# Config override ...
" >> /etc/dovecot/conf.d/10-ssl.conf

DOVECOT_SSL_CERTIFICATE="${DOVECOT_SSL_CERTIFICATE:-/etc/ssl/dovecot/server.pem}"
DOVECOT_SSL_PRIVATE_KEY="${DOVECOT_SSL_PRIVATE_KEY:-/etc/ssl/dovecot/server.key}"

if [ "${DOVECOT_SSL_CERTIFICATE}" != "/etc/ssl/dovecot/server.pem" ]; then
    echo "ssl_cert = <${DOVECOT_SSL_CERTIFICATE}" >> /etc/dovecot/conf.d/10-ssl.conf
fi

if [ "${DOVECOT_SSL_PRIVATE_KEY}" != "/etc/ssl/dovecot/server.key" ]; then
    echo "ssl_key = <${DOVECOT_SSL_PRIVATE_KEY}" >> /etc/dovecot/conf.d/10-ssl.conf
fi


echo -n "
# Config override ...
protocol lmtp {
  mail_plugins = \$mail_plugins sieve
}
" >> /etc/dovecot/conf.d/20-lmtp.conf


echo -n "
# Config override ...
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/home/vmail/%g/%n
}
" >> /etc/dovecot/conf.d/auth-ldap.conf.ext


echo -n "
# Config override ...
" >> /etc/dovecot/dovecot-ldap.conf.ext

if [ -z "${DOVECOT_LDAP_HOST}" ]; then
    echo "Error: Missing mandatory DOVECOT_LDAP_HOST!"
    exit 1
fi


if [ -z "${DOVECOT_LDAP_USER_DN}" ]; then
    echo "Error: Missing mandatory DOVECOT_LDAP_USER_DN!"
    exit 1
fi

if [ -z "${DOVECOT_LDAP_USER_PASSWORD}" ]; then
    echo "Error: Missing mandatory DOVECOT_LDAP_USER_PASSWORD!"
    exit 1
fi

echo "hosts = ${DOVECOT_LDAP_HOST}" >> /etc/dovecot/dovecot-ldap.conf.ext
echo "dn = ${DOVECOT_LDAP_USER_DN}" >> /etc/dovecot/dovecot-ldap.conf.ext
echo "dnpass = ${DOVECOT_LDAP_USER_PASSWORD}" >> /etc/dovecot/dovecot-ldap.conf.ext

if [ -n "${DOVECOT_LDAP_BASE}" ]; then
    echo "base = ${DOVECOT_LDAP_BASE}" >> /etc/dovecot/dovecot-ldap.conf.ext
fi

email_attr="${DOVECOT_LDAP_EMAIL_ATTRIBUTE:-uid}"
password_attr="${DOVECOT_LDAP_PASSWORD_ATTRIBUTE:-userPassword}"

echo "pass_attrs = ${email_attr}=user,${password_attr}=password" >> /etc/dovecot/dovecot-ldap.conf.ext

if [ -n "${DOVECOT_LDAP_QUERY}" ]; then
    echo "pass_filter = ${DOVECOT_LDAP_QUERY}" >> /etc/dovecot/dovecot-ldap.conf.ext
fi


if [ "$#" -gt 0 ]; then
    exec "$@"
else
    /usr/sbin/dovecot

    while true; do
        inotifywait -qq -e modify $DOVECOT_SSL_CERTIFICATE
        echo "$(date) Public key updated, therefore reloading Dovecot config ..."
        sleep 1s
        kill -HUP $(cat /var/run/dovecot/master.pid)
    done
fi
