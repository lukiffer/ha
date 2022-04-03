#!/usr/bin/env bash

set -e

SCRIPT_PATH="$(
  cd "$(dirname "${BASH_SOURCE[0]}")"
  pwd -P
)"

readonly HOME_ASSISTANT_CONFIG_PATH="$SCRIPT_PATH/../config/homeassistant"

function read_secret() {
  local -r property_key="$1"
  yq ".$property_key" < "$HOME_ASSISTANT_CONFIG_PATH/secrets.yaml"
}

function init_mysql_secrets() {
  MYSQL_USER=$(read_secret "mariadb_username")
  MYSQL_PASSWORD=$(read_secret "mariadb_password")
  MYSQL_ROOT_PASSWORD=$(read_secret "mariadb_root_password")
  export MYSQL_USER
  export MYSQL_PASSWORD
  export MYSQL_ROOT_PASSWORD
}

function init_node_red_secrets() {
  NODE_RED_CREDENTIAL_SECRET=$(read_secret "node_red_credential_secret")
  export NODE_RED_CREDENTIAL_SECRET
}

function main() {
  set -x;
  init_mysql_secrets
  init_node_red_secrets

  docker-compose -f "$SCRIPT_PATH/../docker-compose.yaml" up --build
  set +x;
}

main "$@"
