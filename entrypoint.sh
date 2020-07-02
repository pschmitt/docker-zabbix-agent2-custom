#!/usr/bin/env bash

# Create custom group and add zabbix user to it
if [[ -n "$GROUP" ]] || [[ -n "$GID" ]]
then
  EXTRA_ARGS=()
  GROUP="${GROUP:-custom_group}"

  if [[ -n "$GID" ]]
  then
    EXTRA_ARGS+=(-g "$GID")
  fi

  addgroup "${EXTRA_ARGS[@]}" "$GROUP"
  addgroup zabbix "$GROUP"

  unset EXTRA_ARGS GROUP GID
fi

# Include our custom .conf files
for file in /etc/zabbix/zabbix_agentd.d_static/*.conf
do
  filename="$(basename "$file")"
  cp -a "$file" "/etc/zabbix/zabbix_agentd.d/static-${filename}"
  if [[ -e "/etc/zabbix/zabbix_agentd.d/${filename}" ]]
  then
    echo "Removing /etc/zabbix/zabbix_agentd.d/${filename}"
    rm "/etc/zabbix/zabbix_agentd.d/${filename}"
  fi
done

# Run upstream entrypoint script
exec su -s /bin/bash zabbix -c "docker-entrypoint.sh $*"
