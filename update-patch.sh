#!/usr/bin/env bash

cd "$(readlink -f "$(dirname "$0")")" || exit 9

diff -Naur patch/docker-entrypoint.sh.orig patch/docker-entrypoint.sh > docker-entrypoint.patch
