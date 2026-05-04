#!/usr/bin/env bash

function github_list_tags() {
  local repo="$1"

  local headers=(
    -H "Accept: application/vnd.github+json"
  )

  if [[ -n "${GH_TOKEN:-}" ]]; then
    headers+=(-H "Authorization: Bearer ${GH_TOKEN}")
  fi

  curl -fsSL \
    "${headers[@]}" \
    "https://api.github.com/repos/${repo}/tags?per_page=100" \
    | jq -r '.[].name'
}
