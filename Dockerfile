FROM zabbix/zabbix-agent2:latest

USER root

RUN apk add --no-cache smartmontools perl sudo jq

VOLUME ["/etc/zabbix/bin"]

USER zabbix
