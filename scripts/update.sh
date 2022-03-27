#!/usr/bin/env bash

set -e

SCRIPT_PATH="$(
  cd "$(dirname "${BASH_SOURCE[0]}")"
  pwd -P
)"

function main() {
  set -x;
  sudo systemctl stop home-automation.service
  pushd "$SCRIPT_PATH/../"
    docker-compose rm -f
    docker-compose pull
  popd
  sudo systemctl start home-automation.service
  set +x;
}

main "$@"
