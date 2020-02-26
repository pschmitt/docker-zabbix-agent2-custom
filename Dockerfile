FROM zabbix/zabbix-agent2:latest

USER root

RUN apk add --no-cache jq perl smartmontools sudo && \
    sed -i -r 's|^(export PATH=.*)|\1:/etc/zabbix/bin|' /etc/profile

VOLUME ["/etc/zabbix/bin"]

USER zabbix
