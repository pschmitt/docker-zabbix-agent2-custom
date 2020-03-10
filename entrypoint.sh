#!/usr/bin/env bash

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
