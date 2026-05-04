#!/usr/bin/env bash

function ghcr_get_token() {
  local name="$1"
  local ghcr_username="${GHCR_USERNAME:-}"
  local ghcr_token="${GHCR_TOKEN:-${GH_TOKEN:-}}"
  local token_url="https://ghcr.io/token?service=ghcr.io&scope=repository:${name}:pull"

  if [[ -n "$ghcr_username" && -n "$ghcr_token" ]]; then
    curl -fsSL -u "${ghcr_username}:${ghcr_token}" "$token_url" | jq -r '.token'
  else
    curl -fsSL "$token_url" | jq -r '.token'
  fi
}

function ghcr_list_tags() {
  local name="$1"
  local bearer_token

  bearer_token="$(ghcr_get_token "$name")"

  curl -fsSL \
    -H "Authorization: Bearer ${bearer_token}" \
    "https://ghcr.io/v2/${name}/tags/list" \
    | jq -r '.tags[]?'
}

function ghcr_latest_version_tag() {
  local name="$1"
  local track="$2"

  ghcr_list_tags "$name" | latest_tag_for_track "$track"
}
