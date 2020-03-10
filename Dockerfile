FROM zabbixmultiarch/zabbix-agent2:latest

USER root

RUN apk add --no-cache git jq perl smartmontools sudo

ADD install_templates.sh /install_templates.sh
ADD entrypoint.sh /entrypoint.sh

RUN /install_templates.sh \
      https://github.com/pschmitt/zabbix-template-package-updates \
      https://github.com/pschmitt/zabbix-template-reboot-required

VOLUME ["/rootfs"]
VOLUME ["/usr/local/bin"]

# USER zabbix

ENTRYPOINT ["/entrypoint.sh"]
