FROM zabbixmultiarch/zabbix-agent2:latest

USER root

ADD zbx-install-templates.sh /usr/bin/zbx-install-templates.sh
ADD docker-entrypoint.patch /docker-entrypoint.patch

RUN apk add --no-cache git jq perl smartmontools sudo && \
    patch -p1 /usr/bin/docker-entrypoint.sh < /docker-entrypoint.patch && \
    rm /docker-entrypoint.patch && \
    zbx-install-templates.sh \
      mdadm \
      pkg-updates \
      reboot-required \
      restic \
      smartctl \
      speedtest

VOLUME ["/etc/sudoers.d"]
VOLUME ["/rootfs"]
VOLUME ["/usr/local/bin"]

ENV PATH=/zabbix/bin:${PATH} GID= GROUP=

USER zabbix
