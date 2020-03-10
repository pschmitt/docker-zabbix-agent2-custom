#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") GIT_URL..."
}

install_template() {
  local docker_config
  local file
  local filename
  local tmpdir=/git/_pkg
  local zbx_conf_dir=/etc/zabbix/zabbix_agentd.d_static

  echo "Installing $1"

  git clone "$1" "$tmpdir"

  # Dependencies
  if [[ -e "${tmpdir}/dependencies.alpine" ]]
  then
    local dependencies
    # shellcheck disable=2207
    dependencies=($(tr '\n' ' '< "${tmpdir}/dependencies.alpine"))
    apk add --no-cache "${dependencies[@]}"
  fi

  # Copy userparameter configs to /etc/zabbix/zabbix_agentd.d_static
  # We do not use /etc/zabbix/zabbix_agentd.d here since it is supposed to be
  # a volume and therefore would be overwritten on runtime
  mkdir -p /etc/zabbix/zabbix_agentd.d_static
  # TODO Prefer the .docker file
  docker_config=$(find "${tmpdir}/zabbix_agentd.d" -iname "*.docker.conf")
  if [[ -n "$docker_config" ]]
  then
    # Strip the .docker part
    filename=$(basename "$docker_config" | sed 's/.docker//')
    mv -i "$docker_config" "${zbx_conf_dir}/${filename}"
  else
    mv -i "$tmpdir"/zabbix_agentd.conf.d/*.conf "$zbx_conf_dir"
  fi
  mv -i "$tmpdir"/zbx-*.sh /usr/local/bin
  # Remove the .docker extension
  # Otherwise the sudoers files will get ignored
  for file in "$tmpdir"/sudoers.d/*.docker
  do
    filename="$(basename "$file" .docker)"
    mv -i "$file" "/etc/sudoers.d/${filename}"
  done

  chown -R zabbix "$zbx_conf_dir"

  chmod +x /usr/local/bin/*

  chown -R root:root /etc/sudoers.d
  chmod 600 /etc/sudoers.d/*

  rm -rf "$tmpdir"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  case "$1" in
    --help|-h|h|help)
      usage
      exit 0
      ;;
  esac

  if [[ "$#" -eq 0 ]]
  then
    usage
    exit 2
  fi

  set -x

  GIT_URLS=("$@")

  mkdir -p /git

  for git_url in "${GIT_URLS[@]}"
  do
    install_template "$git_url"
  done

  rm -rf /git
fi

# vim: set ft=sh et ts=2 sw=2 :
