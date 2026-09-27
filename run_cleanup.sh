#!/bin/sh

mail_root=/home/vmail

while true; do
    for domain_dir in "$mail_root"/*; do
        [ -d "$domain_dir" ] || continue

        domain=${domain_dir##*/}

        for mailbox_dir in "$domain_dir"/*; do
            [ -d "$mailbox_dir" ] || continue

            local_part=${mailbox_dir##*/}
            address="${local_part}@${domain}"

            if doveadm user "$address" >/dev/null 2>&1; then
                if [ -n "${DOVECOT_SPAM_FOLDER}" ] && [ -n "${DOVECOT_EXPUNGE_SPAM_DAYS}" ]; then
                    count=$(doveadm search -u "${address}" mailbox "${DOVECOT_SPAM_FOLDER}" savedbefore "${DOVECOT_EXPUNGE_SPAM_DAYS}d" | wc -l)
                    if [ "${count}" -gt 0 ]; then
                        doveadm expunge -u "${address}" mailbox "${DOVECOT_SPAM_FOLDER}" savedbefore "${DOVECOT_EXPUNGE_SPAM_DAYS}d"
                        echo "$(date '+%b %e %H:%M:%S') Deleted ${count} old spam messages for ${address}"
                    fi
                fi

                if [ -n "${DOVECOT_EXPUNGE_TRASH_DAYS}" ]; then
                    count=$(doveadm search -u "${address}" mailbox "Trash" savedbefore "${DOVECOT_EXPUNGE_TRASH_DAYS}d" | wc -l)
                    if [ "${count}" -gt 0 ]; then
                        doveadm expunge -u "${address}" mailbox "Trash" savedbefore "${DOVECOT_EXPUNGE_TRASH_DAYS}d"
                        echo "$(date '+%b %e %H:%M:%S') Deleted ${count} old trashed messages for ${address}"
                    fi
                fi
            fi

        done
    done

    sleep 24h
done
