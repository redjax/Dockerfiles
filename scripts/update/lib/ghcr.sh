#!/usr/bin/env bash

function ghcr_list_tags() {
  local name="$1"

  curl -fsSL "https://ghcr.io/v2/${name}/tags/list" \
    | jq -r '.tags[]?'
}

function ghcr_latest_version_tag() {
  local name="$1"
  local track="$2"

  ghcr_list_tags "$name" \
    | latest_tag_for_track "$track"
}
