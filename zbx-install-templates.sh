#!/usr/bin/env bash

GIT_TMP_DIR="$(mktemp -d)"
BIN_DIR=${BIN_DIR:-/zabbix/bin}
SUDOERS_DIR=${SUDOERS_DIR:-/etc/sudoers.d_static}
ZBX_CONF_DIR=${ZBX_CONF_DIR:-/etc/zabbix/zabbix_agentd.d_static}

trap 'rm -rf $GIT_TMP_DIR' EXIT SIGINT

usage() {
  echo "Usage: $(basename "$0") GIT_URL..."
}

init_dirs() {
  mkdir -p "$(dirname "$GIT_TMP_DIR")" "$BIN_DIR" "$SUDOERS_DIR" "$ZBX_CONF_DIR"
}

fix_permissions() {
  chown -R zabbix "$ZBX_CONF_DIR"

  chmod +x "${BIN_DIR}"/*

  patch_sudo_config
  chown -R root:root "$SUDOERS_DIR"
  chmod 600 "${SUDOERS_DIR}"/*
}

patch_sudo_config() {
  local line="#includedir ${SUDOERS_DIR}"
  if ! grep -q "^${line}$" /etc/sudoers
  then
    echo "$line" >> /etc/sudoers
  fi
}

install_dependencies() {
  apk add --no-cache "$@"
}

install_mdadm_template() {
  echo "Installing mdadm template"
  git clone "https://github.com/krom/zabbix_template_md" "$GIT_TMP_DIR"

  cp "${GIT_TMP_DIR}/userparameter_md.conf" "${ZBX_CONF_DIR}/mdadm.conf"

  rm -rf "$GIT_TMP_DIR"
}

install_restic_template() {
  # TODO
  echo "NOT IMPLEMENTED" >&2
}

install_smartctl_template() {
  echo "Installing smartctl template"
  git clone "https://github.com/v-zhuravlev/zbx-smartctl" "$GIT_TMP_DIR"

  install_dependencies perl smartmontools

  cp "${GIT_TMP_DIR}/discovery-scripts/nix/smartctl-disks-discovery.pl" "$BIN_DIR"
  cp "${GIT_TMP_DIR}/sudoers_zabbix_smartctl" "${SUDOERS_DIR}/smartctl"
  cp "${GIT_TMP_DIR}/zabbix_smartctl.conf" "${ZBX_CONF_DIR}/smartctl.conf"
  # Fix path to binary
  sed -i -r "s|= .+(smartctl-disks-discovery.pl)|= ${BIN_DIR}/\1|" \
    "${SUDOERS_DIR}/smartctl"
  sed -i -r "s|,sudo .+(smartctl-disks-discovery.pl)|,sudo ${BIN_DIR}/\1|" \
    "${ZBX_CONF_DIR}/smartctl.conf"

  rm -rf "$GIT_TMP_DIR"
}

install_template() {
  # TODO Install templates that dont match my own template
  local docker_config
  local file
  local filename

  echo "Installing $1"

  git clone "$1" "$GIT_TMP_DIR"

  # Dependencies
  if [[ -e "${GIT_TMP_DIR}/dependencies.alpine" ]]
  then
    local dependencies
    # shellcheck disable=2207
    dependencies=($(tr '\n' ' '< "${GIT_TMP_DIR}/dependencies.alpine"))
    install_dependencies "${dependencies[@]}"
  fi

  # Copy userparameter configs to /etc/zabbix/zabbix_agentd.d_static
  # We do not use /etc/zabbix/zabbix_agentd.d here since it is supposed to be
  # a volume and therefore would be overwritten on runtime
  # TODO Prefer the .docker file
  docker_config=$(find "${GIT_TMP_DIR}/zabbix_agentd.d" -iname "*.docker.conf" 2>/dev/null)
  if [[ -n "$docker_config" ]]
  then
    # Strip the .docker part
    filename=$(basename "$docker_config" | sed 's/.docker//')
    mv -v "$docker_config" "${ZBX_CONF_DIR}/${filename}"
  else
    mv -v "$GIT_TMP_DIR"/zabbix_agentd.d/*.conf "$ZBX_CONF_DIR"
  fi

  # Scripts
  mv -v "$GIT_TMP_DIR"/zbx-*.sh "${BIN_DIR}"

  for file in "$GIT_TMP_DIR"/sudoers.d/*.docker
  do
    # Remove the .docker extension
    # Otherwise the sudoers files will get ignored
    filename="$(basename "$file" .docker)"
    if [[ -e "${SUDOERS_DIR}/${filename}" ]]
    then
      echo "Skipping installation of $file since ${SUDOERS_DIR}/${filename} already exists."
    else
      mv -v "$file" "${SUDOERS_DIR}/${filename}"
    fi
  done

  rm -rf "$GIT_TMP_DIR"
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

  TEMPLATES=("$@")

  init_dirs

  for template in "${TEMPLATES[@]}"
  do
    case "$template" in
      mdadm|raid)
        install_mdadm_template
        ;;
      restic|backup)
        install_restic_template
        ;;
      smartctl|smart)
        install_smartctl_template
        ;;
      speedtest|bandwidth)
        install_template \
          https://github.com/pschmitt/zabbix-template-speedtest
        ;;
      packages|pkg|pkg-updates|linux-package-updates)
        install_template \
          https://github.com/pschmitt/zabbix-template-package-updates
        ;;
      reboot|reboot-required)
        install_template \
          https://github.com/pschmitt/zabbix-template-reboot-required
        ;;
      *)
        install_template "$template"
        ;;
    esac
  done

  fix_permissions

  rm -rf "$GIT_TMP_DIR"
fi

# vim: set ft=sh et ts=2 sw=2 :
