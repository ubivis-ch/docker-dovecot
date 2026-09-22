FROM alpine:3.24

RUN apk add --no-cache \
        dovecot \
        dovecot-ldap \
        dovecot-lmtpd \
        dovecot-pigeonhole-plugin \
        inotify-tools

RUN adduser -s /sbin/nologin -D vmail

COPY docker-entrypoint.sh /

EXPOSE 143 24 4190

ENTRYPOINT [ "/docker-entrypoint.sh" ]
