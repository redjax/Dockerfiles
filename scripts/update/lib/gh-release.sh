#!/usr/bin/env bash

function github_list_tags() {
  local repo="$1"

  curl -fsSL \
    "https://api.github.com/repos/${repo}/tags?per_page=100" \
    | jq -r '.[].name'
}
