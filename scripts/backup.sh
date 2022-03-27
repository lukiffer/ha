#!/usr/bin/env bash

set -e

SCRIPT_PATH="$(
  cd "$(dirname "${BASH_SOURCE[0]}")"
  pwd -P
)"

# shellcheck disable=SC1091
source "$SCRIPT_PATH/utilities.sh"

readonly BACKUP_DIRECTORY_PATH="$SCRIPT_PATH/../backups"

function print_usage() {
  echo
  echo "Usage: backup.sh [OPTIONS]"
  echo
  echo "Creates a signed, encrypted archive of non-declarative configuration files."
  echo
  echo "Options:"
  echo
  echo -e "  --gpg-key\t\t\tThe ID of the GPG key to use for signing and encrypting backups."
  echo -e "  --help\t\t\tShow this help text and exit."
  echo
  echo "Example:"
  echo
  echo "  backup.sh --gpg-key 0000000000000000000000000000000000000000"
}

function create_backup() {
  local -r gpg_recipient="$1"
  local -r name="$2"
  local -r path="$3"
  local -r epoch=$(date +%s)
  local -r archive="$BACKUP_DIRECTORY_PATH/backup-$name-$epoch.tar.gz"

  echo "Creating backup of $name configuration..."
  tar -czf "$archive" "$path"
  echo "Encrypting backup file..."
  gpg --encrypt --sign --recipient "$gpg_recipient" "$archive"
  rm "$archive"
  echo -e "\e[32mBackup created successfully!\e[39m"
}

function main() {
  local gpg_key

  while [[ $# -gt 0 ]]; do
    local key="$1"
    case "$key" in
      --gpg-key)
        gpg_key="$2"
        shift
        ;;
      --help)
        print_usage
        exit
        ;;
      *)
        echo "ERROR: Unrecognized argument: $key"
        print_usage
        exit 1
        ;;
    esac
    shift
  done

  assert_not_empty "--gpg-key" "$gpg_key"
  assert_gpg_key_exists "$gpg_key"

  local -r gpg_recipient=$(gpg --list-keys "$gpg_key" | grep -E '^uid' | sed -e 's/.*<\(.*\)>.*/\1/')

  mkdir -p "$BACKUP_DIRECTORY_PATH"
  create_backup "$gpg_recipient" "homeassistant" "./config/homeassistant"
  create_backup "$gpg_recipient" "nodered" "./config/nodered"
  create_backup "$gpg_recipient" "homeassistant-recorder" "./data/recorder"
}

main "$@"
