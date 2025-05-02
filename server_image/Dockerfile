FROM ubuntu:noble

ARG BORG_VERSION=1.4.0

RUN set -x \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install  -y \
        build-essential \
        libacl1 \
        libacl1-dev \
        liblz4-1 \
        liblz4-dev \
        libssl3t64 \
        libssl-dev \
        libxxhash0 \
        libxxhash-dev \
        libzstd1 \
        libzstd-dev \
        openssh-server \
        python3 \
        python3-pip \
        python3-pkgconfig \
        python3-setuptools \
        python3-setuptools-scm && \
        python3 --version \
        && pip3 install --break-system-packages -v "borgbackup==${BORG_VERSION}" \
        && apt-get remove -y --purge \
            build-essential \
            libacl1-dev \
            liblz4-dev \
            libssl-dev \
            libxxhash-dev \
            libzstd-dev && \
        apt-get autoremove -y --purge && \
        rm -rf /var/lib/apt/lists/*
    

ADD ./entrypoint.sh /

ADD sshd_config /etc/ssh/

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
