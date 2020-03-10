#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") GIT_URL..."
}

patch_sudo_config() {
  local sudoers_dir="${1:-/etc/sudoers.d_static}"
  local line="#includedir ${sudoers_dir}"
  if ! grep -q "^${line}$" /etc/sudoers
  then
    echo "$line" >> /etc/sudoers
  fi
}

install_template() {
  local docker_config
  local file
  local filename
  local tmpdir=/git/_pkg
  local sudoers_dir=/etc/sudoers.d_static
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

  # Scripts
  mv -i "$tmpdir"/zbx-*.sh /usr/local/bin

  # Remove the .docker extension
  # Otherwise the sudoers files will get ignored
  mkdir -p "$sudoers_dir"
  for file in "$tmpdir"/sudoers.d/*.docker
  do
    filename="$(basename "$file" .docker)"
    # mv -i "$file" "/etc/sudoers.d/${filename}"
    mv -i "$file" "${sudoers_dir}/${filename}"
  done

  chown -R zabbix "$zbx_conf_dir"

  chmod +x /usr/local/bin/*

  patch_sudo_config "$sudoers_dir"
  chown -R root:root "$sudoers_dir"
  chmod 600 "${sudoers_dir}"/*

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
