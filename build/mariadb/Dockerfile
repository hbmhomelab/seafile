ARG version=latest
FROM mariadb:$version

ARG cron
ARG uid
ARG gid
ARG password

COPY my.cnf /root/.my.cnf
RUN echo "password=${password}" >> /root/.my.cnf
RUN chmod 0400 /root/.my.cnf

RUN groupadd -g $gid dbbackup
RUN useradd -u $uid -g $gid -s /bin/bash -m dbbackup
RUN mkdir /backup
RUN chown dbbackup:dbbackup /backup

COPY my.cnf /home/dbbackup/.my.cnf
RUN echo "password=${password}" >> /home/dbbackup/.my.cnf
RUN chmod 0400 /home/dbbackup/.my.cnf
RUN chown dbbackup:dbbackup /home/dbbackup/.my.cnf


COPY mariadb-backup-wrapper.sh /usr/local/bin/mariadb-backup-wrapper.sh
RUN chmod 0755 /usr/local/bin/mariadb-backup-wrapper.sh

RUN apt update -qq && apt install -qq -y cron
RUN echo "${cron} dbbackup /usr/local/bin/mariadb-backup-wrapper.sh >/proc/1/fd/1 2>/proc/1/fd/2" > /etc/cron.d/mariadb-backup-cron
RUN chmod 0644 /etc/cron.d/mariadb-backup-cron
