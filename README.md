docker-dovecot
==============

Dovecot image based on Alpine Linux.

It is opiniated in the sense, that it currently "only" supports IMAP (STARTSSL), LMTP (used by SMTP servers as the "MTA"
for local delivery), Sieve and LDAP authentication.

Run
---

There is no "simple" example, that would actually do anything useful. In order for this container to work you'll need
a LDAP server that is reachable and a properly signed SSL keypair.

Below you find a typical example of how to start a container. It's written as a Docker Compose file (`compose.yaml`) and 
it should be fairly easy to "translate" it to a plain `docker run` command.

Please read the section about the "Configuration", in order to understand how you need to configure it for your 
situation (aspacially the different `DOVECOT_LDAP_xxx` variables.

```
services:

  dovecot:
    image: ubivisgmbh/dovecot:latest
    restart: always
    ports:
      - 143:143
      - 24:24
    environment:
      - DOVECOT_LDAP_HOST=openldap
      - DOVECOT_LDAP_USER_DN=cn=admin,dc=example.dc=org
      - DOVECOT_LDAP_USER_PASSWORD=[secret]
      - DOVECOT_LDAP_BASE=ou=Accounts,dc=example,dc=org
    volumes:
      - certificates:/etc/ssl/dovecot
      - data:/home/vmail

volumes:
  data:
```

Configuration (environment variables)
-------------------------------------

### `DOVECOT_LDAP_HOST` (mandatory)

Hostname or IP address (optionally followed by `:[port]`), where your LDAP server listens.

### `DOVECOT_LDAP_USER_DN` (mandatory)

This is the user (in form of a DN (distinguished name) allowed to query the LDAP database (formatted like 
`cn=admin,dc=example,dc=org`).

### `DOVECOT_LDAP_USER_PASSWORD` (mandatory)

The password for the user.

### `DOVECOT_LDAP_BASE` (optional)

Can (and probably should) be set to the distinguished name that is the base subtree in which mail account users are
searched. E.g. `ou=Accounts,dc=example,dc=org`.

### `DOVECOT_LDAP_EMAIL_ATTRIBUTE` (optional, defaults to `uid`)

Sets the attribute in the query result that holds the e-mail address.

### `DOVECOT_LDAP_PASSWORD_ATTRIBUTE` (optional, defaults to `userPassword`)

Sets the attribute in the query result that holds the (hopefully safely encrypted) password.

### `DOVECOT_LDAP_QUERY` (optional, defaults to `(&(objectClass=posixAccount)(uid=%{user}))`)

The LDAP query that searches for an entry that needs to return at least the attributes as defined in 
`DOVECOT_LDAP_EMAIL_ATTRIBUTE` and `DOVECOT_LDAP_PASSWORD_ATTRIBUTE`. 

Some of the most used variables are `%{user}` (full e-mail), `%{user | domain}` (domain part of the e-mail)
and `%{user | username}` (user part of the e-mail). Please also consult the Dovecot documentation (e.g. at 
https://doc.dovecot.org/configuration_manual/config_file/config_variables/).

### `DOVECOT_SSL_CERTIFICATE` (optional, defaults to `/etc/ssl/dovecot/server.pem`)

This needs to point to a valid (and hopefully properly signed) SSL certificate. You need to mount your own 
certificate into the container and point to it.

### `DOVECOT_SSL_PRIVATE_KEY` (optional, defaults to `/etc/ssl/dovecot/server.key`)

This needs to point to a valid private SSL key. You need to mount your own certificate into the container and
point to it.

Please make sure the file is *not* world-readable! It is actually best, if it has the permissions `root:root 0400`.

Data persistence
----------------

### `/home/vmail`

This is where all the Maildir's are. You quite definitely want to persist this.

### `/etc/ssl/dovecot` or something alike (quite probably)

It makes sense that you mount your own SSL keypair into the container. See the explanations for the environment 
variables `DOVECOT_SSL_CERTIFICATE` and `DOVECOT_SSL_PRIVATE_KEY`.

Upgrade from Dovecot 2.3.x to 2.4.x
-----------------------------------

As of 2026-09-21 the newest version runs Dovecot 2.4.x which introduced changes how to configure it. While most
is hidden from the user of this Docker image, you might need to update `DOVECOT_LDAP_BASE` or `DOVECOT_LDAP_QUERY`
with the new variable expansion syntax (c.f. https://doc.dovecot.org/2.4.5/installation/upgrade/2.3-to-2.4.html).

Notes
-----

This container constantly checks for changes in the file `DOVECOT_SSL_CERTIFICATE` and in case there is a modification,
it makes Dovecot reread the contiguration. This way it's possible to have no interruptions on renewed certificates. This
is especially useful for short-living certificates as the ones created by "Let's encrypt" (which was actually the reason
to implement this feature).

There is no need to backup the configuration as it gets completely rebuilt on every container start.

Development / Bugs
------------------

Development takes place on Github:

https://github.com/ubivis-ch/docker-dovecot

Please report any issues to:

https://github.com/ubivis-ch/docker-dovecot/issues
