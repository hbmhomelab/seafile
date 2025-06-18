#!/bin/bash

TIMESTAMP=`date '+%Y%m%dT%H%M'`
BACKUP_DIR="/backup"
TARGET_DIR="${BACKUP_DIR}/${TIMESTAMP}"

# Check that the .my.cnf credentials work.

mariadb-admin version &>/dev/null

if [ $? -ne 0 ]
then
  echo "Error: cannot connect - service is down or MARIADB_ROOT_PASSWORD is not correct"
  exit 1
fi

# Check that backup has not already been taken.

if [ -d $TARGET_DIR ]
then
  echo "Backup for ${TIMESTAMP} already taken"
  exit 1
fi

# Work out which databases to backup.

DATABASES=""

if [ "${BACKUP:-all}" == "all" ]
then

  # If all is specified in BACKUP or it is empty, backup everything apart from
  # the information and performance schema databases.

  DATABASES=$(mariadb -s -e \
    "SELECT TABLE_SCHEMA FROM information_schema.TABLES WHERE TABLE_SCHEMA NOT IN ('information_schema','performance_schema') GROUP BY TABLE_SCHEMA;" | xargs )

else

  # If specific databases are listed in BACKUP, check each listed database and
  # only back them up if they exist and are not empty.

  for DATABASE in $BACKUP
  do
    EXISTS=$(mariadb -s -e \
      "SELECT TABLE_SCHEMA FROM information_schema.TABLES WHERE TABLE_SCHEMA LIKE '${DATABASE}' GROUP BY 1" | xargs)
    if [ -z ${EXISTS:+z} ]
    then
      echo "Warning: database ${DATABASE} does not exist or is empty - excluding"
    else
      if [ -z ${DATABASES:+z} ]
      then
        DATABASES="${DATABASE}"
      else
        DATABASES="${DATABASES} ${DATABASE}"
      fi
    fi
  done

fi

# Perform the backup then make the backup point-in-time consistent (prepare) and
# create transportable tablespaces (export) for each table in each schema.

if [ -z ${DATABASES:+z} ]
then
  echo "Warning: no non-empty databases found to backup"
else
  echo "Notice: backing up databases ${DATABASES} to ${TARGET_DIR}"
  mkdir $TARGET_DIR \
   && mariadb-backup --backup --databases="${DATABASES}" --target-dir=$TARGET_DIR \
   && mariadb-backup --prepare --export --target-dir=$TARGET_DIR \
   && chown -R mdbuser:mdbuser $TARGET_DIR
fi

# Create a helper script for each schema that uses the transportable tablespaces
# created above to recover data.

for DATABASE in $DATABASES
do

  DATABASE_DIR="${TARGET_DIR}/${DATABASE}"
  if [ -d $DATABASE_DIR ]
  then

    # Create SQL to discard and import tablespaces for each table in the
    # database.

    DISCARD_SQL="${DATABASE_DIR}/discard_tablespaces.sql"
    IMPORT_SQL="${DATABASE_DIR}/import_tablespaces.sql"

    TABLES=$(mariadb -s -e \
      "SELECT CONCAT(TABLE_SCHEMA, '.', TABLE_NAME) FROM information_schema.TABLES WHERE TABLE_SCHEMA LIKE '${DATABASE}'" | xargs)
    touch $DISCARD_SQL $IMPORT_SQL
    for TABLE in $TABLES
    do
      echo "ALTER TABLE ${TABLE} DISCARD TABLESPACE;" >> $DISCARD_SQL
      echo "ALTER TABLE ${TABLE} IMPORT TABLESPACE;" >> $IMPORT_SQL
    done

    # Create a script that discards the schema tablespaces, copies the backed up
    # transportable tablespaces in and imports them.

    RESTORE_SCRIPT="${DATABASE_DIR}/restore.sh"
    RESTORE_DIR="/var/lib/mysql/${DATABASE}"

    echo '#!/bin/sh' > $RESTORE_SCRIPT
    echo 'mariadb < ./discard_tablespaces.sql' >> $RESTORE_SCRIPT
    echo 'cp *.cfg *.frm *.ibd' $RESTORE_DIR >> $RESTORE_SCRIPT
    echo 'chown -R mysql:mysql' $RESTORE_DIR >> $RESTORE_SCRIPT
    echo 'mariadb < ./import_tablespaces.sql' >> $RESTORE_SCRIPT
    chmod 755 $RESTORE_SCRIPT

  fi
done

# Check that KEEP is an integer.

case "${KEEP}" in

  '') KEEP=0;;

  *[!0-9]*)
    echo "Warning: KEEP should be an integer - setting to 0"
    KEEP=0

esac

# If MARIADB_BACKUP_KEEP is non-zero, ensure only that number of backups are kept.

if [ $KEEP -gt 0 ]
then
  OLD_BACKUPS=$(ls -1t $BACKUP_DIR | grep -E '[0-9]+T[0-9]+$' | tail -n "+$((++KEEP))" | xargs)
  for OLD in $OLD_BACKUPS
  do
    echo "Warning: removing old backup ${OLD} from ${BACKUP_DIR}"
    rm -rf "${BACKUP_DIR}/${OLD}"
    rm -f "${BACKUP_DIR}/backup-${OLD}.log"
  done
else
  echo "Warning: all backups are being retained - check ${BACKUP_DIR}"
fi
