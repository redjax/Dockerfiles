#!/usr/bin/env bash

function ghcr_list_tags() {
  local name="$1"

  curl -fsSL "https://ghcr.io/v2/${name}/tags/list" \
    | jq -r '.tags[]?'
}

function ghcr_latest_version_tag() {
  local name="$1"
  
  ghcr_list_tags "$name" \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -n1
}
