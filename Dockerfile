FROM zabbix/zabbix-agent2:latest

USER root

RUN apk add --no-cache smartmontools speedtest-cli perl sudo jq

USER zabbix
