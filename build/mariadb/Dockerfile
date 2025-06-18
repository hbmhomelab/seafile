ARG version=latest
FROM mariadb:$version

ARG uid
ARG gid
ARG cron
ARG backup
ARG keep
ARG password

# Install cron and supervisor.
RUN apt update -qq && apt install -qq -y --no-install-recommends cron supervisor

# Configure mariadb credentials for the root user.
RUN echo "[client]" > /root/.my.cnf
RUN echo "user=root" >> /root/.my.cnf
RUN echo "password=${password}" >> /root/.my.cnf
RUN chmod 0400 /root/.my.cnf

# Configure backup user who will own backup files.
RUN groupadd -g $gid mdbuser
RUN useradd -u $uid -g $gid -s /bin/bash -m mdbuser
RUN mkdir /backup
RUN chown mdbuser:mdbuser /backup

# Configure mariadb backups.
COPY mariadb-backup-wrapper.sh /usr/local/bin/mariadb-backup-wrapper.sh
RUN chmod 0755 /usr/local/bin/mariadb-backup-wrapper.sh
RUN echo "KEEP=${keep}" > /root/mariadb-backup-cron
RUN echo "BACKUP=${backup}" >> /root/mariadb-backup-cron
RUN echo "${cron} /usr/local/bin/mariadb-backup-wrapper.sh >/proc/1/fd/1 2>/proc/1/fd/2" >> /root/mariadb-backup-cron
RUN crontab /root/mariadb-backup-cron

# Configure supervisor to start cron and mariadb.
COPY supervisord.conf /etc/supervisor/supervisord.conf

# Run supervisor in the container, which will run and manage cron and mariadb.
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
