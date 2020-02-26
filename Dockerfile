FROM zabbix/zabbix-agent2:latest

USER root

RUN apk add --no-cache jq perl smartmontools sudo

VOLUME ["/etc/zabbix/bin"]

USER zabbix
