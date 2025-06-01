#!/bin/bash

set noglob

# Location of the configuration files.

SEAFILE_DIR="/opt/seafile"
STARTUP_DIR="${SEAFILE_DIR}/seafile-server-latest"
SEAHUB_SETTINGS="${SEAFILE_DIR}/conf/seahub_settings.py"

# Make a backup copy of the seahub settings file.

TIMESTAMP=`date '+%Y%M%dT%H%M'`
cp -f $SEAHUB_SETTINGS "${SEAHUB_SETTINGS}.${TIMESTAMP}"

# List of settings that should be added to seahub_settings.py from the environment.

SEAHUB_SETTINGS_VARS="CSRF_TRUSTED_ORIGINS EMAIL_PORT EMAIL_USE_TLS"
SEAHUB_QUOTED_SETTINGS_VARS="EMAIL_HOST EMAIL_HOST_USER EMAIL_HOST_PASSWORD \
  DEFAULT_FROM_EMAIL SERVER_EMAIL"

# Additional variables that can be derived from environment variables.

SERVER_EMAIL="${DEFAULT_FROM_EMAIL}"
CSRF_TRUSTED_ORIGINS="[\"https://${SEAFILE_SERVER_HOSTNAME}\"]"

# Add or replace each setting in seahub_settings.py.

for VAR in $SEAHUB_SETTINGS_VARS
do
  if grep "^${VAR}" $SEAHUB_SETTINGS > /dev/null 2>&1
  then
    VALUE=$(echo ${!VAR} | sed -E 's/([\/&])/\\\1/g')
    sed -i -e "/^${VAR}\s*=/s/\s*=.*\$/ = ${VALUE}/" $SEAHUB_SETTINGS
  else
    echo "${VAR} = ${!VAR}" >> $SEAHUB_SETTINGS
  fi
done

for VAR in $SEAHUB_QUOTED_SETTINGS_VARS
do
  if grep -w "^${VAR}" $SEAHUB_SETTINGS > /dev/null 2>&1
  then
    VALUE=$(echo ${!VAR} | sed -E 's/([\/&])/\\\1/g')
    sed -i -e "/^${VAR}\s*=/s/\s*=.*\$/ = '${VALUE}'/" $SEAHUB_SETTINGS
  else
    echo "${VAR} = '${!VAR}'" >> $SEAHUB_SETTINGS
  fi
done

# Restart seafile server and seahub.

$STARTUP_DIR/seafile.sh restart
$STARTUP_DIR/seahub.sh restart
