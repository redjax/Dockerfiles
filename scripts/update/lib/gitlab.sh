#!/usr/bin/env bash

function gitlab_list_tags() {
  local name="$1"
  local registry_base="${GITLAB_REGISTRY_BASE:-}"

  if [[ -z "$registry_base" ]]; then
    echo "[ERROR] GITLAB_REGISTRY_BASE is required for gitlab registry lookups" >&2
    return 1
  fi

  curl -fsSL "${registry_base}/v2/${name}/tags/list" \
    | jq -r '.tags[]?'
}

function gitlab_latest_version_tag() {
  local name="$1"
  local track="$2"

  gitlab_list_tags "$name" \
    | latest_tag_for_track "$track"
}
