#!/bin/sh

set -e

# Check for incomming Nginx server commands or subcommands only
if [ "$1" = "nginx" ] || [ "${1#-}" != "$1" ]; then
    if [ "${1#-}" != "$1" ]; then
        set -- nginx "$@"
    fi

    chown nginx:nginx /var/cache/cgit
    chmod u+g /var/cache/cgit

    # If there is some public key in keys folder
    # then it copies its contain in authorized_keys file
    if [ "$(ls -A /git-server/keys/)" ]; then
      cd /home/git
      cat /git-server/keys/*.pub > .ssh/authorized_keys
      chown -R git:git .ssh
      chmod 700 .ssh
      chmod -R 600 .ssh/*
    fi

    # Checking permissions and fixing SGID bit in repos folder
    # More info: https://github.com/jkarlosb/git-server-docker/issues/1
    if [ "$(ls -A /git-server/repos/)" ]; then
      mkdir /git-server/repos
      cd /git-server/repos
      chown -R git:git .
      chmod -R ug+rwX .
      find . -type d -exec chmod g+s '{}' +
    fi

    # -D flag avoids executing sshd as a daemon
    /usr/sbin/sshd -D &

    # Replace environment variables only if `USE_CUSTOM_CONFIG` is not defined or equal to `false`
    if [[ -z "$USE_CUSTOM_CONFIG" ]] || [[ "$USE_CUSTOM_CONFIG" = "false" ]]; then
        envsubst < /tmp/cgitrc.tmpl > /etc/cgitrc
    fi

    spawn-fcgi \
        -u nginx -g nginx \
        -s /var/run/fcgiwrap.sock \
        -n -- /usr/bin/fcgiwrap \
        & exec "$@"
else
    exec "$@"
fi
