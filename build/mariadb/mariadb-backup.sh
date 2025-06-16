#!/bin/bash

set -xo pipefail

TIMESTAMP=`date '+%Y%m%dT%H'`
TARGET_DIR="/backup/${TIMESTAMP}"

# Check that we have the required information in the environment.

if [ -z ${MARIADB_ROOT_PASSWORD:+z} ]
then
  echo "Error: MARIADB_ROOT_PASSWORD not set in environment"
  exit 1
fi

if [ -z ${MARIADB_BACKUP_DATABASES:+z} ]
then
  echo "Error: MARIADB_BACKUP_DATABASES not set in environment"
  exit 1
fi

# Check that the root password works.

mariadb-admin -u root --password="${MARIADB_ROOT_PASSWORD}" version &>/dev/null

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

if [ ${MARIADB_BACKUP_DATABASES:-all} -eq "all" ]
then

  # If all is specified in MARIADB_BACKUP_DATABASES or it is empty, backup
  # everything apart from the information and performance schema databases.

  DATABASES=$(mariadb -u root --password="${MARIADB_ROOT_PASSWORD}" -s -e \
    "SELECT TABLE_SCHEMA FROM information_schema.TABLES WHERE TABLE_SCHEMA NOT IN ('information_schema','performance_schema') GROUP BY TABLE_SCHEMA;" | xargs )

else

  # If specific databases are listed in MARIADB_BACKUP_DATABASES, check each
  # listed database and only back them up if they exist and are not empty.

  for DATABASE in $MARIADB_BACKUP_DATABASES
  do
    EXISTS=$(mariadb -u root --password="${MARIADB_ROOT_PASSWORD}" -s -e \
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

if [ -z ${DATABASES:+z} ]
then
  echo "Warning: no non-empty databases found to backup"
else
  mkdir $TARGET_DIR && mariadb-backup -u root --password="${MARIADB_ROOT_PASSWORD}" --backup \
    --databases="${DATABASES}" \
    --target-dir="${TARGET_DIR}"
fi
