#!/usr/bin/env bash

function dockerhub_repo_path() {
  local name="$1"

  if [[ "$name" == */* ]]; then
    printf '%s\n' "$name"
  else
    printf 'library/%s\n' "$name"
  fi
}

function dockerhub_list_tags() {
  local name="$1"
  local repo

  repo="$(dockerhub_repo_path "$name")"

  curl -fsSL "https://hub.docker.com/v2/repositories/${repo}/tags?page_size=100" \
    | jq -r '.results[].name'
}

function dockerhub_latest_version_tag() {
  local name="$1"
  local track="$2"

  dockerhub_list_tags "$name" \
    | latest_tag_for_track "$track"
}
