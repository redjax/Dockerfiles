#!/usr/bin/env bash

function acr_list_tags() {
  local name="$1"
  local acr_login_server="${ACR_LOGIN_SERVER:-}"
  
  if [[ -z "$acr_login_server" ]]; then
    echo "[ERROR] ACR_LOGIN_SERVER is required for acr registry lookups" >&2
    return 1
  fi

  curl -fsSL "https://${acr_login_server}/v2/${name}/tags/list" \
    | jq -r '.tags[]?'
}

function acr_latest_version_tag() {
  local name="$1"
  
  acr_list_tags "$name" \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -n1
}
