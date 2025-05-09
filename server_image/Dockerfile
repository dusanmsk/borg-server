FROM alpine:3.19

RUN apk update && \
    apk add --no-cache \
    openssh \
    borgbackup

ADD ./entrypoint_alpine.sh /entrypoint.sh
ADD sshd_config /etc/ssh/

EXPOSE 22
ENTRYPOINT ["/entrypoint.sh"]
