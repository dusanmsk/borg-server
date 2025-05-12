#!/bin/bash

if [ "$DEBUG" == "1" ]; then
    set -x
fi

if [ ! -d /borg ]; then
    echo "Backup directory /borg does not exist. Did you forget to mount it?"
    exit 1
fi

userdel borg >/dev/null 2>&1
groupdel borg >/dev/null 2>&1
if [ "$BORG_UID" != "" ]; then
    # delete conflicting user/group
    if getent passwd "$BORG_UID" > /dev/null 2>&1; then
        userdel -r "$(getent passwd "$BORG_UID" | cut -d: -f1)"
    fi
    if getent group "$BORG_GID" > /dev/null 2>&1; then
        groupdel "$(getent group "$BORG_GID" | cut -d: -f1)"
    fi
    # create user and group with specified UID/GID
    addgroup --gid $BORG_GID borg 
    adduser --uid $BORG_UID --gid $BORG_GID --disabled-password --gecos "Borg Backup" --home /borg --no-create-home --quiet borg 
else    
    # create user and group with default UID/GID
    adduser --disabled-password --gecos "Borg Backup" --home /borg --no-create-home --quiet borg 
fi

# setup on first start
if [ ! -d /borg/.ssh ]; then
    mkdir -p /borg/.ssh/sshd
    chown -R root:root /borg/.ssh/sshd
    cd /borg/.ssh/sshd
    echo "Generating SSH keys..."
    ssh-keygen -t rsa -b 4096 -f /borg/.ssh/sshd/ssh_host_rsa_key -N ""
    ssh-keygen -t ecdsa -b 521 -f /borg/.ssh/sshd/ssh_host_ecdsa_key -N ""
    ssh-keygen -t ed25519 -f /borg/.ssh/sshd/ssh_host_ed25519_key -N ""
    chmod 600 /borg/.ssh/sshd/ssh_host_*
    cd -
    mkdir -p /borg/repositories
    chown borg:borg /borg/ /borg/repositories
fi

# inject authorized keys and setup file permissions
echo "$AUTHORIZED_KEYS" > /borg/.ssh/authorized_keys
chown -R borg:borg /borg/.ssh/
chmod 700 /borg/.ssh/authorized_keys

# start opensshd
mkdir -p /run/sshd
if [ "$DEBUG" == "1" ]; then
    echo "Starting sshd in debug mode... Only one connection will be possible, so use with caution."
    exec /usr/sbin/sshd -D -e -ddd
else
    exec /usr/sbin/sshd -D -e
fi

