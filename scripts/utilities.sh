#!/usr/bin/env bash

function assert_not_empty() {
  local -r arg_name="$1"
  local -r arg_value="$2"

  if [[ -z "$arg_value" ]]; then
    echo "ERROR: The value for '$arg_name' cannot be empty"
    print_usage
    exit 1
  fi
}

function assert_gpg_key_exists() {
  local -r gpg_key="$1"
  if ! gpg --list-keys "$gpg_key" > /dev/null; then
    echo "The GPG key with ID $gpg_key was not found on this system. Please install it and try again.";
    exit 1
  fi
}
