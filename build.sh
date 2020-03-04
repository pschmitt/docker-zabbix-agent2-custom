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
  echo -1 | sudo tee /proc/sys/fs/binfmt_misc/qemu-aarch64 > /dev/null
  echo ':qemu-aarch64:M:0:\x7f\x45\x4c\x46\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:CF' | \
    sudo tee /proc/sys/fs/binfmt_misc/register > /dev/null
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
