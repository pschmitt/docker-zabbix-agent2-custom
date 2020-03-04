#!/usr/bin/env bash

cd "$(readlink -f "$(dirname "$0")")" || exit 9

set -e

BASE_IMAGE_AMD64=zabbix/zabbix-agent2:latest
BASE_IMAGE_ARMHF="pschmitt/zabbix-agent-alpine:4.4.6"
IMAGE_NAME_AMD64="pschmitt/zabbix-agent2-custom:latest"
IMAGE_NAME_ARMHF="pschmitt/zabbix-agent-custom:armhf"

usage() {
  echo "Usage: $0 docker|docker_arm"
}

__build_docker() {
  # Default to amd64
  local base_img="$BASE_IMAGE_AMD64"
  local img_name="$IMAGE_NAME_AMD64"

  if [[ "$1" == "armhf" ]]
  then
    base_img="$BASE_IMAGE_ARMHF"
    img_name="$IMAGE_NAME_ARMHF"
  fi

  docker build \
    --build-arg BASE_IMAGE="$base_img" \
    -t "$img_name" .
  docker push "$img_name"
}

build_docker() {
  __build_docker amd64
}

build_docker_arm() {
  # Setup qemu emulation
  if [[ "$(uname -m)" == "x86_64" ]]
  then
    docker run --rm --privileged docker/binfmt:820fdd95a9972a5308930a2bdfb8573dd4447ad3
  fi
  # Build image
  __build_docker armhf
}

case "$1" in
  help|h|-h|--help)
    usage
    ;;
  docker|docker_amd64|docker_x86_64)
    build_docker
    ;;
  docker_arm|docker_aarch64|docker_rpi)
    build_docker_arm
    ;;
  *)
    usage
    exit 2
    ;;
esac
