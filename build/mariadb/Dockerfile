ARG version=latest
FROM mariadb:$version

ARG cron
ARG uid
ARG gid

RUN groupadd -g $gid dbbackup
RUN useradd -u $uid -g $gid -s /bin/bash -m dbbackup
RUN mkdir /backup
RUN chown dbbackup:dbbackup /backup

COPY mariadb-backup.sh /usr/local/bin/mariadb-backup.sh
RUN chmod 0755 /usr/local/bin/mariadb-backup.sh

RUN apt update -qq && apt install -qq -y cron
RUN echo "${cron} dbbackup /usr/local/bin/mariadb-backup >/proc/1/fd/1 2>/proc/1/fd/2" > /etc/cron.d/mariadb-backup-cron
RUN chmod 0644 /etc/cron.d/mariadb-backup-cron
