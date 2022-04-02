#!/usr/bin/env bash

set -e

SCRIPT_PATH="$(
  cd "$(dirname "${BASH_SOURCE[0]}")"
  pwd -P
)"

readonly HOME_ASSISTANT_CONFIG_PATH="$SCRIPT_PATH/../config/homeassistant"

function read_secret() {
  local -r property_key="$1"
  sops --decrypt --extract "[\"$property_key\"]" "$HOME_ASSISTANT_CONFIG_PATH/secrets.encrypted.yaml"
}

function decrypt_secrets_file() {
  local -r source_path="$1"
  local -r type="${2:-yaml}"
  local -r dest_path=${source_path/.encrypted/}
  sops --decrypt --input-type "$type" --output-type "$type" "$source_path" > "$dest_path"
}

function init_homeassistant_secrets() {
  decrypt_secrets_file "$HOME_ASSISTANT_CONFIG_PATH/secrets.encrypted.yaml"
}

function init_zwave_secrets() {
  ZWAVE_NETWORK_KEY=$(read_secret "zwave_network_key")
  sed -e "s/{{ZWAVE_NETWORK_KEY}}/$ZWAVE_NETWORK_KEY/" "$HOME_ASSISTANT_CONFIG_PATH/options.tpl.xml" > "$HOME_ASSISTANT_CONFIG_PATH/options.xml"
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
  init_homeassistant_secrets
  init_zwave_secrets
  init_mysql_secrets
  init_node_red_secrets

  docker-compose -f "$SCRIPT_PATH/../docker-compose.yaml" up --build
  set +x;
}

main "$@"
