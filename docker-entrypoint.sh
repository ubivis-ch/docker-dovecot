#!/bin/sh

contains_old_style_variables() {
    case ${1-} in
        *%u*|*%d*|*%n*|*%w*) return 0 ;;
        *) return 1 ;;
    esac
}

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

if contains_old_style_variables "${DOVECOT_LDAP_BASE}"; then
    echo "Error: Using deprecated style variables in DOVECOT_LDAP_BASE!"
    exit 1
fi

if contains_old_style_variables "${DOVECOT_LDAP_QUERY}"; then
    echo "Error: Using deprecated style variables in DOVECOT_LDAP_QUERY!"
    exit 1
fi

echo -n "
dovecot_config_version = 2.4.2
dovecot_storage_version = 2.4.0

info_log_path = /dev/stdout
log_path = /dev/stderr

protocols {
  imap = yes
  lmtp = yes
}

auth_mechanisms = plain

mail_driver = maildir
mail_uid = vmail
mail_gid = vmail
mail_path = /home/vmail/%{user | domain}/%{user | username}/Maildir

namespace inbox {
  inbox = yes
}


ssl = required

ssl_server_cert_file = ${DOVECOT_SSL_CERTIFICATE:-/etc/ssl/dovecot/server.pem}
ssl_server_key_file = ${DOVECOT_SSL_PRIVATE_KEY:-/etc/ssl/dovecot/server.key}

service lmtp {
  user = vmail

  inet_listener lmtp {
    port = 24
  }
}

protocol lmtp {
  mail_plugins {
    sieve = yes
  }
}

service anvil {
  unix_listener anvil-connect-limit {
    group = vmail
    mode = 0660
  }
}

ldap_uris = ldap://${DOVECOT_LDAP_HOST}
ldap_auth_dn = ${DOVECOT_LDAP_USER_DN}
ldap_auth_dn_password = ${DOVECOT_LDAP_USER_PASSWORD}

ldap_base = ${DOVECOT_LDAP_BASE:-}

userdb static {
  fields {
    uid = vmail
    gid = vmail
    home = /home/vmail/%{user | domain}/%{user | username}
  }
}

passdb ldap {
  ldap_filter = ${DOVECOT_LDAP_QUERY:-(&(objectClass=posixAccount)(uid=%{user\}))}

  fields {
    password = %{ldap:${DOVECOT_LDAP_PASSWORD_ATTRIBUTE:-userPassword}}
    user = %{ldap:${DOVECOT_LDAP_EMAIL_ATTRIBUTE:-uid}}
  }
}
" > /etc/dovecot/dovecot.conf

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
