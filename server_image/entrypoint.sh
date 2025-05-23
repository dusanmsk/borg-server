#!/bin/sh

if [ "$DEBUG" = "1" ]; then
    set -x
fi

if [ ! -d /borg ]; then
    echo "Backup directory /borg does not exist. Did you forget to mount it?"
    exit 1
fi

deluser borg >/dev/null 2>&1
delgroup borg >/dev/null 2>&1

if [ -n "$BORG_UID" ]; then
    if id -u "$BORG_UID" >/dev/null 2>&1; then
        deluser "$(getent passwd "$BORG_UID" | cut -d: -f1)"
    fi
    if getent group "$BORG_GID" >/dev/null 2>&1; then
        delgroup "$(getent group "$BORG_GID" | cut -d: -f1)"
    fi
    addgroup -g "$BORG_GID" borg
    adduser -u "$BORG_UID" -G borg -h /borg -H -D borg
else
    addgroup borg
    adduser -G borg -h /borg -H -D borg
fi

passwd -u borg

if [ ! -d /borg/.ssh ]; then
    mkdir -p /borg/.ssh/sshd
    chown -R root:root /borg/.ssh/sshd
    cd /borg/.ssh/sshd || exit 1
    echo "Generating SSH keys..."
    ssh-keygen -t rsa -b 4096 -f /borg/.ssh/sshd/ssh_host_rsa_key -N ""
    ssh-keygen -t ecdsa -b 521 -f /borg/.ssh/sshd/ssh_host_ecdsa_key -N ""
    ssh-keygen -t ed25519 -f /borg/.ssh/sshd/ssh_host_ed25519_key -N ""
    chmod 600 /borg/.ssh/sshd/ssh_host_*
    cd - || exit 1
    mkdir -p /borg/repositories
    chown borg:borg /borg /borg/repositories
fi

echo "$AUTHORIZED_KEYS" > /borg/.ssh/authorized_keys
chown -R borg:borg /borg/
chmod 755 /borg
chown -R root:root /borg/.ssh/sshd
chmod 0644 /borg/.ssh/authorized_keys
chmod -R 0600 /borg/.ssh/sshd

echo "Running borg server as user: $(id -u borg):$(id -g borg)"

mkdir -p /run/sshd
if [ "$DEBUG" = "1" ]; then
    echo "Starting sshd in debug mode... Only one connection will be possible, so use with caution."
    exec /usr/sbin/sshd -D -e -ddd
else
    echo "Starting sshd..."
    exec /usr/sbin/sshd -D -e
fi
