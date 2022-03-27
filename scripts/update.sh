#!/usr/bin/env bash

function stop_containers() {
  docker-compose stop
}

function reset_image_cache() {
  docker-compose rm -f
}

function pull_latest_images() {
  docker-compose pull
}

function main() {
  set -x;
  stop_containers
  reset_image_cache
  pull_latest_images
  set +x;
  ./start.sh
}

main "$@"
