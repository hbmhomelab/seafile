#!/bin/bash

set noglob

# Location of the configuration files.

SEAFILE_DIR="/opt/seafile"
STARTUP_DIR="${SEAFILE_DIR}/seafile-server-latest"
SEAHUB_SETTINGS="${SEAFILE_DIR}/conf/seahub_settings.py"
SEAFDAV_CONF="${SEAFILE_DIR}/conf/seafdav.conf"

# Make a backup copy of the configuration files.

TIMESTAMP=`date '+%Y%M%dT%H%M'`
cp -f $SEAHUB_SETTINGS "${SEAHUB_SETTINGS}.${TIMESTAMP}"
cp -f $SEAFDAV_CONF "${SEAFDAV_CONF}.${TIMESTAMP}"

# List of settings that should be added to seahub_settings.py from the environment.

SEAHUB_SETTINGS_VARS="CSRF_TRUSTED_ORIGINS EMAIL_PORT EMAIL_USE_TLS"
SEAHUB_QUOTED_SETTINGS_VARS="EMAIL_HOST EMAIL_HOST_USER EMAIL_HOST_PASSWORD \
  DEFAULT_FROM_EMAIL SERVER_EMAIL SITE_TITLE"

# Additional variables that can be derived from the environment.

SERVER_EMAIL="${DEFAULT_FROM_EMAIL}"
CSRF_TRUSTED_ORIGINS="[\"https://${SEAFILE_SERVER_HOSTNAME}\"]"

echo

# Add or replace each setting in seahub_settings.py.

for VAR in $SEAHUB_SETTINGS_VARS
do
  if grep "^${VAR}" $SEAHUB_SETTINGS > /dev/null 2>&1
  then
    echo -n "Replacing ${VAR} ..."
    VALUE=$(echo ${!VAR} | sed -E 's/([\/&])/\\\1/g')
    sed -i -e "/^${VAR}\s*=/s/\s*=.*\$/ = ${VALUE}/" $SEAHUB_SETTINGS
    echo " done"
  else
    echo -n "Setting ${VAR} ..."
    echo "${VAR} = ${!VAR}" >> $SEAHUB_SETTINGS
    echo " done"
  fi
done

for VAR in $SEAHUB_QUOTED_SETTINGS_VARS
do
  if grep -w "^${VAR}" $SEAHUB_SETTINGS > /dev/null 2>&1
  then
    echo -n "Replacing ${VAR} ..."
    VALUE=$(echo ${!VAR} | sed -E 's/([\/&])/\\\1/g')
    sed -i -e "/^${VAR}\s*=/s/\s*=.*\$/ = '${VALUE}'/" $SEAHUB_SETTINGS
    echo " done"
  else
    echo -n "Setting ${VAR} ..."
    echo "${VAR} = '${!VAR}'" >> $SEAHUB_SETTINGS
    echo " done"
  fi
done

# Turn on WebDAV.

echo -n "Enabling WebDAV ..."
sed -i -e "/^enabled\s*=/s/\s*=.*\$/ = true/" $SEAFDAV_CONF
echo " done"

# Restart seafile server and seahub.

$STARTUP_DIR/seafile.sh restart
$STARTUP_DIR/seahub.sh restart
